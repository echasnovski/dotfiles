# Prompt that adjusts based on part priority and available width
#
# Requires Nu>=0.105.0
use ($nu.default-config-dir | path join "project-root.nu") [ get_project_root get_lang_icon ]

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
  { combine_parts $parts $inv_id }
}

# `parts`  - list of closures each taking integer width `budget` as input and
#            returning part's current string representation. Can be empty (there
#            will be two adjacent spaces) or `null` (not show completely).
#            Arranged in "processing order" (from highest to lowest priority).
# `inv_id` - indexes that rearrange `parts` in the original "display order".
def combine_parts [parts: list<closure>, inv_id: list<int>]: nothing -> string {
  # Cache Git info for better performance of git parts
  $env.prompt_latest_git_data = (compute_git_data)

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
  --color: closure,
  --icon: closure,
  --priority: float = $default_priorty,
  --root: closure,
  --trunc_dir_width: int = 2,
  --trunc_char: string = '…',
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { { "blue" } }
  let icon = $icon | default { { |p, l| make_path_icon $p $l } }
  let root = $root | default { { |p| get_project_root $p } }
  { part: { |budget| make_pwd $budget $icon $color $root $trunc_dir_width $trunc_char }, priority: $priority }
}

# Make path "fancy short" relative to the root:
# - Home directory is shortened to '~'.
# - All root parent directories are shortened to `trunc_dir_width` visible
#   characters and appended with grey `trunc_char` character.
# - Root basename is made bold.
# - Root children are shown in full.
def format_path [
  path: path,
  color: string,
  root: string,
  trunc_dir_width: int,
  trunc_char: string,
]: nothing -> string {
  let p = $path | hide_home_path
  if ($root == '') { return $p }

  let r = $root | hide_home_path
  let p_rel = try { $p | path relative-to $r } catch { return $p }

  let root_parts = $r | path split
  let prefix = $root_parts | slice ..-2 | each { |d| $d | trunc_dirname $trunc_dir_width $trunc_char $color } | path join
  let root_name = $root_parts | slice (-1).. | get 0
  let root_name_colored = $"(ansi attr_bold)($root_name)(ansi reset)(ansi $color)"

  let parts = if ($p_rel == '') { [$prefix, $root_name_colored] } else { [$prefix, $root_name_colored, $p_rel] }
  $parts | path join
}

def make_path_icon [path: path, langs: list<string>]: nothing -> string {
  if ($path == $nu.home-dir) { return '󰋜 ' }
  if ($path | path split | any { |d| $d == 'nvim' }) { return ' ' }

  let l_icons = $langs | each { |l| $l | get_lang_icon } | compact
  if ($l_icons | is-not-empty) { return ($l_icons | str join '') }

  if ($env.prompt_latest_git_data.is_git) { return '󰊢 ' }
  '󰉋 '
}

def make_pwd [
  budget: int,
  icon: closure,
  color: closure,
  root: closure
  trunc_dir_width: int
  trunc_char: string
]: nothing -> string {
  let pwd = $env.PWD
  let col = do $color $pwd

  # Try first to get from in-memory database for performance (as root
  # computation is/can be expensive with many disk reads)
  let res = pwd_string_cache_get $pwd
  let res = if ($res == null) {
    let r = do $root $pwd
    let path = format_path $pwd $col ($r | get path) $trunc_dir_width $trunc_char
    let i = do $icon $pwd ($r | get langs)
    $"($i)($path)" | pwd_string_cache_set $pwd
  } else {$res}

  $res | trunc_path $budget | add_color $col
}

def pwd_string_cache_get [path: path]: nothing -> record {
  let data = try {
    stor open | query db "select * from __prompt_pwd WHERE path == :path" --params { path: $path }
  } catch {
    stor create --table-name __prompt_pwd --columns { path: str, pwd_string: str }
    null
  }
  if ($data | is-empty) { return null }
  $data | get pwd_string.0
}

def pwd_string_cache_set [path: path]: string -> string {
  let $res = $in
  { path: $path, pwd_string: $res } | stor insert --table-name __prompt_pwd
  $res
}

# Git -------------------------------------------------------------------------
export def compute_git_data []: nothing -> record {
  let git_dir_cli = (do -i { git rev-parse --git-dir } | complete)
  if $git_dir_cli.exit_code != 0 { return { is_git: false } }
  let git_dir = $git_dir_cli.stdout | str trim | path expand

  # Branch
  let branch = (git rev-parse --abbrev-ref HEAD)
  let branch = if ($branch == "HEAD") { (git rev-parse --short HEAD) } else {$branch}

  # Status
  let staged =    (git_count-with-timeout 10 ["diff" "--cached" "--numstat"])
  let unstaged =  (git_count-with-timeout 10 ["ls-files" "-m" "-d"])
  let untracked = (git_count-with-timeout 10 ["ls-files" "-o" "--exclude-standard"])
  let conflicts = (git_count-with-timeout 10 ["diff" "--name-only" "--diff-filter=U"])

  let stash_log = ($git_dir | path join "logs" "refs" "stash" | into string)
  let stashes = if ($stash_log | path exists) { try { open $stash_log | lines | length } catch { 0 } } else { 0 }

  # "In progress" status
  let states = [
    [state,         file];
    ["apply",       ($git_dir | path join "rebase-apply")]
    ["bisect",      ($git_dir | path join "BISECT_LOG")]
    ["cherry-pick", ($git_dir | path join "CHERRY_PICK_HEAD")]
    ["merge",       ($git_dir | path join "MERGE_HEAD")]
    ["rebase",      ($git_dir | path join "rebase-merge")]
    ["revert",      ($git_dir | path join "REVERT_HEAD")]
  ]
  let active_actions = $states | where {|it| $it.file | path exists } | get state | uniq
  let in_progress = if ($active_actions | is-not-empty) { $active_actions | str join "," } else { "" }

  # "Ahead/behind" indicator
  let counts_cli = (do -i { git rev-list --count --left-right "HEAD...@{upstream}" } | complete)
  let counts = if $counts_cli.exit_code != 0 { "0\t0" } else { $counts_cli.stdout }
  let counts_parts = $counts | str trim | split row "\t"
  let ahead = ($counts_parts | get 0 | into int)
  let behind = ($counts_parts | get 1 | into int)

  return {
    is_git: true,
    git_dir: $git_dir,
    branch: $branch,
    in_progress: $in_progress,
    ahead: $ahead,
    behind: $behind,
    staged: $staged,
    unstaged: $unstaged,
    untracked: $untracked,
    conflicts: $conflicts,
    stashes: $stashes
  }
}

export def prompt_part_gitbranch [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { { 'cyan' } }
  let icon = $icon | default { { || ' ' } }
  { part: { |budget| make_gitbranch $budget $icon $color}, priority: $priority }
}

def make_gitbranch [budget: int, icon: closure, color: any]: nothing -> string {
  let $git_data = $env.prompt_latest_git_data
  if not $git_data.is_git { return null }

  let branch = $git_data.branch
  let state = if ($git_data.in_progress == "") {""} else {$" &($git_data.in_progress)"}
  let behind = if ($git_data.behind > 0) { $" <($git_data.behind)" } else { "" }
  let ahead = if ($git_data.ahead > 0) { $" >($git_data.ahead)" } else { "" }
  let behind = if ($git_data.behind > 0) { $" <($git_data.behind)" } else { "" }

  $"(do $icon $git_data)($branch)($state)($ahead)($behind)" | add_color (do $color $git_data)
}

export def prompt_part_gitstatus [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { { 'cyan' } }
  let icon = $icon | default { { || ' ' } }
  { part: { |budget| make_gitstatus $budget $icon $color}, priority: $priority }
}

# Mostly a replication of how powerlevel10k shows Git status
def make_gitstatus [budget: int, icon: closure, color: any]: nothing -> string {
  let $git_data = $env.prompt_latest_git_data
  if not $git_data.is_git { return null }

  let staged    = format_for_gitstatus $git_data.staged    "@"
  let unstaged  = format_for_gitstatus $git_data.unstaged  "~"
  let untracked = format_for_gitstatus $git_data.untracked "+"
  let conflicts = format_for_gitstatus $git_data.conflicts "!"
  let stashes   = format_for_gitstatus $git_data.stashes   "*"

  let arr = [$conflicts $staged $unstaged $untracked $stashes] | compact
  let status = if (($arr | length) == 0) { "-" } else ($arr | str join " ")
  $"(do $icon $git_data)($status)" | add_color (do $color $git_data)
}

def format_for_gitstatus [n: int, prefix: string]: nothing -> string {
  if ($n == 0) { return null }
  $prefix + (if ($n < 0) {"?"} else {$n | into string})
}

def git_count-with-timeout [max_time: int, args: list<string>] {
  let res = (do -i { timeout ($max_time * 0.001) git ...$args } | complete)

  match $res.exit_code {
    124 => -1 # Timeout
    0   => (if ($res.stdout | is-empty) { 0 } else { $res.stdout | lines | uniq | length | into int })
    _   => -2  # Unknown error
  }
}

# Time ------------------------------------------------------------------------
export def prompt_part_time [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { { "yellow" } }
  let icon = $icon | default { (make_time_icon) }
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
  let color = $color | default { { || if ($env.LAST_EXIT_CODE == 0) { "green" } else { "red" } } }
  let icon = $icon | default { (make_cmdduration_icon) }
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
  let code = if ($env.LAST_EXIT_CODE == 0) { "" } else { $" 󰅖 ($env.LAST_EXIT_CODE)" }
  $"(do $icon $dur)($dur)($code)" | add_color (do $color $dur)
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
def trunc_path [width: int]: string -> string {
  let s = $in
  let s_width = $s | ansi strip | str length --grapheme-clusters
  if ($s_width <= $width or $width <= 0) { return $s }

  for i in 1..($s | str length) {
    let res = $s | str substring --grapheme-clusters ($i)..(-1)
    let res_width = $res | ansi strip | str length --grapheme-clusters
    if ($res_width <= $width) { return $res }
  }
  return ''
}

def trunc_dirname [width: int, trunc_char: string, main_color: any]: string -> string {
  let s = $in
  let res_width = $s | str length --grapheme-clusters
  let trunc_width = $trunc_char | ansi strip | str length --grapheme-clusters
  if ($res_width <= ($width + $trunc_width) or $width <= 0) { return $s }
  let prefix = $s | str substring --grapheme-clusters 0..($width - 1)
  $"($prefix)($trunc_char)(ansi reset)(ansi $main_color)"
}

def hide_home_path []: path -> path {
  let $p = $in
  try { '~' | path join ($p | path relative-to $nu.home-dir) } catch { $p }
}
