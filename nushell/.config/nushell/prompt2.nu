const default_priorty = 100.0
const default_fill_priorty = -100.0

# Input is a list of records with fields:
# `part`     - closure returning string to display. See `combine_parts`.
# `priority` - integer representing order in which parts should be fit into
#              terminal width; higher priorties are processed first.
#              Default priority is usually 100 (`-100` for `fill` to be
#              processed last).
export def prompt_make []: list -> closure {
  let data = (
    $in | lift_index orig_id | default $default_priorty priority |
    # Sort by decreasing priority breaking ties by increasing id
    update priority { |row| (0 - $row.priority) } | sort-by priority orig_id
  )
  let parts = $data | get part
  let inv_id = $data | lift_index inv_id | sort-by orig_id | get inv_id
  { combine_parts $parts $inv_id}
}

# `parts`  - list of closures each taking integer width `budget` as input and
#            returning part's current string representation. Can be empty (there
#            will be two adjacent spaces) or `null` (not show completely).
#            Arranged in "processing order" (from highest to lowest priority).
# `inv_id` - indexes that rearrange `parts` in the original "display order".
def combine_parts [parts: list<closure>, inv_id: list<int>]: nothing -> string {
  # Cache Git info for better performance of git parts
  $env.prompt_latest_gstat = gstat

  # Iteratively process parts in their priority order
  let init = { strparts: [], budget: (term size).columns, offset: 0 }
  let strparts = $parts |
    reduce --fold $init { |p, state| append_part $p $state } |
    get strparts

  # Rearrange parts in their original intended order and join into string
  # This also automatically removes `null` elements.
  # $parts.index | each { |i| $strparts | get $i } | str join ' '
  let res = $inv_id | each { |i| $strparts | get $i } | str join ' '
  (ansi reset) + $res
}

# Process callable part and update tracking state with it
# State is:
# `strparts` - list of already computed string parts or `null`s.
# `budget`   - number left terminal cells to non-processed parts.
# `offset`   - integer offset when computing width to account for
#              a mandatory single space between parts.
#              Basically 0 before first added string part, 1 - after.
def append_part [
  part: closure,
  state: record<strparts: list, budget: int, offset: int>
]: nothing -> record<strparts: list, budget: int, offset: int> {
  # Call part with current budget and decide if it should be added
  let str = do $part $state.budget
  let w = $str | default '' | ansi strip | str length --grapheme-clusters
  let should_add = $str != null and (($w + $state.offset) <= $state.budget)

  # Update state
  let new_str = if $should_add {$str} else {null}
  let new_parts = $state.strparts | append [$new_str]
  let new_budget = $state.budget - (if $should_add {$w + $state.offset} else {0})
  let new_offset = if $should_add {1} else {$state.offset}
  { strparts: $new_parts, budget: $new_budget, offset: $new_offset }
}

# Parts =======================================================================
# Working directory -----------------------------------------------------------
export def prompt_part_pwd [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { "blue" }
  let icon = $icon | default { |p| make_path_icon $p }
  { part: { |budget| make_pwd $budget $icon $color }, priority: $priority }
}

def format_path [p: string, color: string]: nothing -> string {
  # TODO: if it is inside Git repo, make it "fancy short". As in:
  # - All repo's parent directories with 4+ chars are truncated to first two
  #   plus grey '…'.
  # - Repo basename is bold.
  # - Repo's subdirectores are in full.
  # Maybe consider always dynamically shorten directories if not enough budget?
  # Examples:
  # - '~/directory/aaa/repo/subdir/subdir-2' ->
  #   '~/di(ansi grey)…(ansi reset)/aaa/(ansi bold)repo(ansi reset)/subdir/subdir-2'
  #
  # TODO: Maybe introduce a more general concept of "project" and "root_markers"
  # that can compute parent path as "project root" *and* its "source". Like:
  # - Root markers can be an array of something like:
  #   [
  #     { kind: 'lua', markers: [ 'stylua.toml', 'luarc.json' ] },
  #     { kind: 'git', markers: [ '.git' ] },
  #     { kind: 'editorconfig', markers: [ '.editorconfig' ] },
  #   ]
  # - Returned project kind can be forwarded to icon computation.
  # - Returned project root path can be used to shorten path.
  let home = $nu.home-path
  let path_sep = char path_sep
  let colored_path_sep = $"(ansi attr_bold)($path_sep)(ansi reset)(ansi $color)"
  if ($p | str starts-with $home) { return ($p | str replace $home '~') }
  $p
}

def make_path_icon [p: string]: nothing -> string {
  if ($p == $nu.home-path) { return '󰋜 ' }
  if ($p | path split | any { |d| $d == 'nvim' }) { return ' ' }
  if ($env.prompt_latest_gstat.stashes >= 0) { return '󰊢 ' }
  '󰉋 '
}

def make_pwd [budget: int, icon: closure, color: any]: nothing -> string {
  let pwd = $env.PWD
  let col = do $color $pwd
  let path = format_path $pwd $col
  $"(do $icon $pwd)($path)" | fit_to_width $budget | add_color $col
}

# Git -------------------------------------------------------------------------
export def prompt_part_gitbranch [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { 'cyan' }
  let icon = $icon | default { || ' ' }
  { part: { |budget| make_gitbranch $budget $icon $color}, priority: $priority }
}

def make_gitbranch [budget: int, icon: closure, color: any]: nothing -> string {
  let $gs = $env.prompt_latest_gstat
  if ($gs.stashes < 0) { return null }

  let behind = if ($gs.behind > 0) { $"<($gs.behind)" } else { "" }
  let ahead = if ($gs.ahead > 0) { $">($gs.ahead)" } else { "" }
  let compare = (if ($behind != "" or $ahead != "") { " " } else { "" }) + $behind + $ahead
  $"(do $icon $gs)($gs.branch)($compare)" | add_color (do $color $gs)
}

export def prompt_part_gitstatus [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { 'cyan' }
  let icon = $icon | default { || ' ' }
  { part: { |budget| make_gitstatus $budget $icon $color}, priority: $priority }
}

# Mostly a replication of how powerlevel10k shows Git status
def make_gitstatus [budget: int, icon: closure, color: any]: nothing -> string {
  let $gs = $env.prompt_latest_gstat
  if ($gs.stashes < 0) { return null }

  let stashes = if ($gs.stashes > 0) {$"*($gs.stashes)"}
  let conflicts = if ($gs.conflicts > 0) {$"!($gs.conflicts)"}

  let n_staged = (
    $gs.idx_added_staged +
    $gs.idx_modified_staged +
    $gs.idx_deleted_staged +
    $gs.idx_renamed +
    $gs.idx_type_changed
  )
  let staged = if ($n_staged > 0) {$"@($n_staged)"}

  let n_unstaged = (
    $gs.wt_modified +
    $gs.wt_deleted +
    $gs.wt_renamed +
    $gs.wt_type_changed
  )
  let unstaged = if ($n_unstaged > 0) {$"~($n_unstaged)"}

  let untracked = if ($gs.wt_untracked > 0) { $"?($gs.wt_untracked)" }

  let arr = [$conflicts $staged $unstaged $untracked $stashes] | compact

  let status = if (($arr | length) == 0) { "-" } else ($arr | str join " ")
  $"(do $icon $gs)($status)" | add_color (do $color $gs)
}

# Time ------------------------------------------------------------------------
export def prompt_part_time [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { "yellow" }
  let icon = $icon | default (make_time_icon)
  { part: { |budget| make_time $budget $icon $color}, priority: $priority }
}

def make_time_icon []: nothing -> closure {
  # Dynamically choose icon depending on the hour of day
  let hour_icons = {
    '01': '󱑋 '
    '02': '󱑌 '
    '03': '󱑍 '
    '04': '󱑎 '
    '05': '󱑏 '
    '06': '󱑐 '
    '07': '󱑑 '
    '08': '󱑒 '
    '09': '󱑓 '
    '10': '󱑔 '
    '11': '󱑕 '
    '12': '󱑖 '
  }
  { |now| $hour_icons | get ($now | format date '%I') }
}
def make_time [budget: int, icon: closure, color: closure]: nothing -> string {
  let now = date now
  let time = date now | format date "%H:%M:%S"
  $"(do $icon $now)($now | format date "%H:%M:%S")" | add_color (do $color $now)
}

export def prompt_part_cmdduration [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { || if ($env.LAST_EXIT_CODE == 0) { "green" } else { "red" } }
  let icon = $icon | default (make_cmdduration_icon)
  { part: { |budget| make_cmdduration $budget $icon $color}, priority: $priority }
}

def make_cmdduration_icon []: nothing -> closure {
  # Dynamically choose icon depending on the duration
  {
    |dur|
    if ($dur < 1sec) { return '󰚭 '}
    if ($dur < 1min) { return '󰔟 '}
    if ($dur < 1hr) { return '󱦟 '}
    '󰞌 '
  }
}

def make_cmdduration [budget: int, icon: closure, color: closure]: nothing -> string {
  let dur = (($env.CMD_DURATION_MS | into int) * 1000000) | into duration
  $"(do $icon $dur)($dur)" | add_color (do $color $dur)
}

# Fill ------------------------------------------------------------------------
export def prompt_part_fill [
  --budget_fraction: float = 1.0
  --char: string = '-'
  --color: any = 'default'
  --priority: float = $default_fill_priorty
]: nothing -> record<part: closure> {
  {
    part: { |budget| make_fill ($budget_fraction * $budget | math floor) $char $color },
    priority: $priority
  }
}

def make_fill [budget: int, char: string, color: string] {
  if ($budget == 0) { return null }
  '' | fill --character $char --width ($budget - 1) | add_color $color
}

# Utilities ===================================================================
def lift_index [into_col: string]: table -> table {
  $in | enumerate | flatten | rename --column { index: $into_col }
}

def add_color [color]: string -> string { (ansi $color) + $in + (ansi reset) }

# Fit string into width by removing characters from left (designed for
# shortening path). Should also account for possible ansi sequences.
def fit_to_width [width: int]: string -> string {
  let s = $in
  let res_width = $s | ansi strip | str length --grapheme-clusters
  if ($res_width <= $width or $width <= 0) { return $s }
  $s | str substring --grapheme-clusters 1..(-1) | fit_to_width $width
}
