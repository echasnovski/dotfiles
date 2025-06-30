$env.dirjump = {
  session: (random chars --length 25),
  db_path: ($nu.default-config-dir | path join "dirjump.sqlite3"),
  next_jump_kind: 'outside',
  jumps: {
    ignore: { |before, after| false },
  },
  completions: {
    # Notes:
    # - Suggestions are made compact:
    #   - If path is marked, show mark.
    #   - If path is subdir, replace current dir with ".".
    #   - If path is subdir of HOME, replace it with "~".

    # Closure determining whether to ignore particular jump data
    ignore: {
      |jump_data|
      (
        $jump_data.before == '' or
        $jump_data.after == $env.PWD or
        $jump_data.after == $nu.home-path
      )
    },

    # Feature coefficients. Applied to feature ranks:
    # - Rank is a number between 0 and `n` (number of ranked elements).
    #   The bigger the number, the "better" the element is.
    # - For boolean: 0 if `false`, `n` (maximum) if `true`.
    # - For non-boolean: unique values from 0 to `n-1` in increasing order.
    #
    # Default values are chosen to show bookmarks on top, then prefer
    # subdir/local, then by decreasing "frecency". Using coefficients
    # for all of them allows to order within each "higher level" group by
    # the rest of feature. For example, bookmarks are ordered based by
    # decreasing value of other features.
    coefs: {
      is_bookmark: 4, # Whether path corresponds to bookmark
      is_subdir: 1,   # Whether target path is subdirectory of current dir
      is_local: 1,    # Whether target path was jumped into from current dir
      latest: 1,      # Time of the latest jump into target path
      n: 1,           # Number of jumps into target path
    }
  }
}

# Track
if not ($env.dirjump.db_path | path exists) {
  # Create a database file (couldn't find a better way to do it with Nu itself)
  [ { a: 1 } ] | into sqlite $env.dirjump.db_path --table-name tmp
  let db = open $env.dirjump.db_path
  $db | query db "drop table tmp"

  # Creating tables is modeled after how built-in SQLite history table is created:
  # https://github.com/nushell/nushell/issues/9403#issuecomment-1922075163

  # Jumps
  let jumps_columns = [
    'id integer primary key autoincrement',
    'time datetime not null',
    'session text not null',
    'after text not null',
    'before text',
    'kind integer not null',
  ]
  $db | query db $"create table if not exists jumps \(($jumps_columns | str join ', ')\)"
  $db | query db "create index if not exists idx_jumps_time on jumps(time)"
  $db | query db "create index if not exists idx_jumps_session on jumps(session)"
  $db | query db "create index if not exists idx_jumps_after on jumps(after)"
  $db | query db "create index if not exists idx_jumps_before on jumps(before)"
  $db | query db "create index if not exists idx_jumps_kind on jumps(kind)"

  # Bookmarks
  $db | query db "create table if not exists bookmarks (mark text not null, path text not null) strict"
  $db | query db "create index if not exists idx_bookmarks_mark on bookmarks(mark)"
  $db | query db "create index if not exists idx_bookmarks_path on bookmarks(path)"
}

def --env register_jump [before, after]: nothing -> nothing {
  if (do $env.dirjump.jumps.ignore $before $after) { return }
  let kind = $env.dirjump | default 'outside' next_jump_kind | get next_jump_kind
  let params = {
    time: (date now),
    session: $env.dirjump.session,
    after: $after,
    before: $before,
    kind: $kind,
  }
  open $env.dirjump.db_path |
    query db "insert into jumps values(null, :time, :session, :after, :before, :kind)" --params $params

  $env.dirjump.next_jump_kind = 'outside'
}

$env.config = ($env.config | upsert hooks {
  env_change: {
    PWD: [ { |before, after| register_jump $before $after } ]
  }
})

def lift_index [into_col: string]: table -> table {
  $in | enumerate | flatten | rename --column { index: $into_col }
}

def rank_column [col_name: string]: list<any> -> list<int> {
  let t = $in
  let rank_name = $"rank_($col_name)"
  let is_bool = ($t | get $col_name | get 0 | describe) == 'bool'

  if $is_bool {
    let n = $t | length
    return ($t | insert $rank_name { |row| if ($row | get $col_name) {$n} else {0} })
  }

  let ranks = $t
  | select $col_name
  | lift_index orig_id
  | sort-by ([ $col_name ] | into cell-path)
  | lift_index $rank_name
  | sort-by orig_id
  | select $rank_name

  $t | merge $ranks
}

# Smart completion based on features of jump history
def dirjump_completer [] {
  let db = open $env.dirjump.db_path
  let bookmarks = $db | query db "select mark, path from bookmarks"
  let opts = $env.dirjump.completions
  let coefs = $opts.coefs
  let pwd = $env.PWD

  let candidates = $db
    # Get all non-ignored jumps
    | query db "select * from jumps"
    | where { |jump_data| not (do $opts.ignore $jump_data) }
    # Compute unique target paths with features from their history
    | group-by after --to-table |
    | insert latest { |row| $row.items.time | math max }
    | insert n { |row| $row.items | length }
    | insert is_local { |row| $row.items.before | any { |p| $p == $pwd } }
    | reject items
    # Compute extra data
    | join --left $bookmarks after path
    | reject path
    | insert is_bookmark { |row| $row.mark | is-not-empty }
    | insert rel_path { |row| try { '.' | path join ($row.after | path relative-to $pwd) } catch { '' } }
    | insert is_subdir { |row| $row.rel_path | is-not-empty }
    # Compute rankings
    | rank_column latest
    | rank_column n
    | rank_column is_local
    | rank_column is_subdir
    | rank_column is_bookmark
    | insert rank {
        |row|
        (
          $coefs.latest * $row.rank_latest
          + $coefs.n * $row.rank_n
          + $coefs.is_local * $row.rank_is_local
          + $coefs.is_subdir * $row.rank_is_subdir
          + $coefs.is_bookmark * $row.rank_is_bookmark
        )
      }
    | sort-by --reverse rank
    # Compute candidates with descriptions, making output more compact
    | insert short_path {
      |row|
      if ($row.is_subdir) { return $row.rel_path }
      try { '~' | path join ($row.after | path relative-to $nu.home-path) } catch { $row.after }
    }
    | insert value { |row| if ($row.is_bookmark) {$row.mark} else {$row.short_path}}
    | insert description { |row| if ($row.is_bookmark) {$row.short_path} else {''}}
    | select value description

  { options: { sort: false, partial: false }, completions: $candidates }
}

# Work with directory jumps:
# - `dj --mark project` - mark current directory as "project"
# - `dj --unmark` - unmark current directory
# - `dj project` - jump to directory marked as "project"
# - `dj path/to/dir` - jump to directory (use './path' if same as bookmark)
# - `dj <Tab>` - show jumping target suggestions based on previous jumps
# - `dj --list bookmarks` - show available bookmarks
# - `dj --list jumps` - show jump history
# - `dj --prune 4wk` - delete jumps that are older than some cut-off
def --env dj [
  target?: string@dirjump_completer,
  --mark: string,
  --unmark,
  --list: string,
  --prune: duration
]: nothing -> any {
  let db = open $env.dirjump.db_path

  # Mark current working directory
  if ($mark | is-not-empty) {
    $db | query db "delete from bookmarks where mark = :mark" --params { mark: $mark }
    $db | query db "insert into bookmarks values(:mark, :pwd)" --params { mark: $mark, pwd: (pwd) }
    return
  }

  # Unmark current working directory
  if $unmark {
    $db | query db "delete from bookmarks where path = :pwd" --params { pwd: (pwd) }
    return
  }

  # List available bookmarks or jumps
  if ($list | is-not-empty) {
    if not ($list == 'bookmarks' or $list == 'jumps') {
      error make { msg: $"Value of `--list` flag should be either 'bookmarks' or 'jumps'. Not ($target)" }
    }
    return ($db | query db $"select * from ($list)" | into value)
  }

  # Prune jumps that are older than timeout
  if ($prune | is-not-empty) {
    let params = { cutoff: ((date now) - $prune) }
    let db = open $env.dirjump.db_path
    let n_pruned = $db
      | query db "select count() as n from jumps where time <= :cutoff" --params $params
      | get n.0
    $db | query db "delete from jumps where time <= :cutoff" --params $params
    print $"Pruned ($n_pruned) jump(if ($n_pruned == 1) {''} else {'s'})"
    return
  }

  # Jump
  let $target = $target | default (dirjump_completer | get completions.0.value)

  let bookmark_path = $db |
    query db "select path from bookmarks where mark = :target" --params { target: $target }
  if ($bookmark_path | is-not-empty) {
    $env.dirjump.next_jump_kind = 'dirjump_mark'
    cd ($bookmark_path | get path.0)
    return
  }

  if not ($target == '-' or ($target | path exists)) {
    error make { msg: $"($target) is neither bookmark nor path" }
  }

  $env.dirjump.next_jump_kind = if ($target == '-') {'dirjump_alt'} else {'dirjump_path'}
  cd $target
}
