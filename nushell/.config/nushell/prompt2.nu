# Dynamicly adjusted prompt
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
  $env.prompt_latest_gstat = gstat --no-tag

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
  if ($path == $nu.home-path) { return '󰋜 ' }
  if ($path | path split | any { |d| $d == 'nvim' }) { return ' ' }

  let l_icons = $langs | each { |l| $l | get_lang_icon } | compact
  if ($l_icons | is-not-empty) { return ($l_icons | str join '') }

  if ($env.prompt_latest_gstat.stashes >= 0) { return '󰊢 ' }
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
  let r = do $root $pwd
  let path = format_path $pwd $col ($r | get path) $trunc_dir_width $trunc_char
  let i = do $icon $pwd ($r | get langs)
  $"($i)($path)" | trunc_path $budget | add_color $col
}

# Git -------------------------------------------------------------------------
export def prompt_part_gitbranch [
  --color: closure
  --icon: closure
  --priority: float = $default_priorty,
]: nothing -> record<part: closure, priority: float> {
  let color = $color | default { { 'cyan' } }
  let icon = $icon | default { { || ' ' } }
  { part: { |budget| make_gitbranch $budget $icon $color}, priority: $priority }
}

const repo_states = {
  "Clean": "",
  "Merge": "merge",
  "Revert": "revert",
  "RevertSequence": "revert-s",
  "CherryPick": "cherry-pick",
  "CherryPickSequence": "cherry-pick-s",
  "Bisect": "bisect",
  "Rebase": "rebase",
  "RebaseInteractive": "rebase-i",
  "RebaseMerge": "rebase-m",
  "ApplyMailbox": "am",
  "ApplyMailboxOrRebase": "am-rebase",
}

def make_gitbranch [budget: int, icon: closure, color: any]: nothing -> string {
  let $gs = $env.prompt_latest_gstat
  if ($gs.stashes < 0) { return null }

  let behind = if ($gs.behind > 0) { $"<($gs.behind)" } else { "" }
  let ahead = if ($gs.ahead > 0) { $">($gs.ahead)" } else { "" }
  let compare = (if ($behind != "" or $ahead != "") { " " } else { "" }) + $behind + $ahead

  let gs_state = $gs | default 'None' state | get state
  let state = $repo_states | default "" $gs_state | get $gs_state
  let state = if ($state == "") {""} else {$" &($state)"}
  $"(do $icon $gs)($gs.branch)($state)($compare)" | add_color (do $color $gs)
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
  let home = $nu.home-path
  let $p = $in
  if ($p | str starts-with $home) { return ($p | str replace $home '~') }
  $p
}
