# Original source of parts: https://github.com/nushell/nu_scripts/blob/main/modules/prompt/oh-my.nu
use std repeat

# Combine left and right prompt parts in order until full part fits:
# - `parts_left` from left to right. Put on left.
# - `parts_right` from right to left. Put on right.
# - Fill extra space in between with fill character.
#
# All parts are separated by a single space.
#
# Both `parts_left` and `parts_right` are lists of functions returning one
# prompt part (already colored string) each.
#
# `fill` is a string that is displayed as a single character.
# Like `'-'` or `(ansi red) + '-' + (ansi reset)`.
def combine_parts [parts_left parts_right fill fill_color] {
  # Compute parts that fit total width
  let tot_width = (term size).columns
  let l = take_until_fits $parts_left $tot_width
  let r = take_until_fits ($parts_right | reverse) ($l.budget_width - 1) # `-1` to ensure single cell between left and right
  let middle_width = $r.budget_width + 1

  # Construct output
  let left = $l.parts | str join ' '
  let middle = (make_middle $middle_width $fill) | add_color $fill_color
  let right = $r.parts | reverse | str join ' '

  $left + $middle + $right
}

def take_until_fits [parts width_available] {
  mut budget_width = $width_available
  mut is_first = true
  mut res = []
  for $part in $parts {
    let p = do $part
    let w = $p | ansi strip | str length --grapheme-clusters
    if ($w > 0) {
      # Adjust width by 1 if it needs to account for cell in between parts
      let offset = if ($is_first) {0} else {1}
      if (($w + $offset) > $budget_width) { break }

      $res = $res | append $p
      $budget_width = $budget_width - $w - $offset
      $is_first = false
    }
  }

  { parts: $res, budget_width: $budget_width }
}

def make_middle [width fill] {
  if ($width <= 0) { return "" }
  if ($width <= 1) { return " " }
  " " + ("" | fill --character $fill --width ($width - 2)) + " "
}

def add_color [col] { (ansi $col) + $in + (ansi reset) }

def format_path [p] {
  # TODO: if it is inside Git repo, make it "fancy short". As in:
  # - All repo's parent directories with 4+ chars are truncated to first two
  #   plus grey '…'.
  # - Repo basename is bold.
  # - Repo's subdirectores are in full.
  # Examples:
  # - '~/directory/aaa/repo/subdir/subdir-2' ->
  #   '~/di(ansi grey)…(ansi reset)/aaa/(ansi bold)repo(ansi reset)/subdir/subdir-2'
  let home = $nu.home-path
  if ($p | str starts-with $home) { return ($p | str replace $home '~') }
  $p
}

def compute_path_icon [p] {
  if ($p | path split | any { |d| $d == 'nvim' }) { return '' }
  '󰉋'
}

def part_path [] {
  let pwd = $env.PWD
  # TODO: Cache computed paths for performance
  mut res = $"(compute_path_icon $pwd) (format_path $pwd)"

  # Ensure that output (which might contain ANSI codes) always fits terminal
  let tot_width = (term size).columns
  let res_width = $res | ansi strip | str length --grapheme-clusters
  if ($res_width > $tot_width) {
    let full_width = $res | str length --grapheme-clusters
    for i in 1..$full_width {
      # Remove characters from left as they are least important
      $res = $res | str substring --grapheme-clusters 1..(-1)
      let cur_width = $res | ansi strip | str length --grapheme-clusters
      if ($cur_width <= $tot_width) { break }
    }
  }

  $res | add_color "blue"
}

def part_git_branch [gs] {
  if ($gs.stashes < 0) { return "" }
  let behind = if ($gs.behind > 0) { $"<($gs.behind)" } else { "" }
  let ahead = if ($gs.ahead > 0) { $">($gs.ahead)" } else { "" }
  let compare = (if ($behind != "" or $ahead != "") { " " } else { "" }) + $behind + $ahead
  $" ($gs.branch)($compare)" | add_color "cyan"
}

# Mostly a replication of how powerlevel10k shows Git status
def part_git_status [gs] {
  if ($gs.stashes < 0) { return "" }

  mut arr = []

  if ($gs.stashes > 0) { $arr = $arr | append $"*($gs.stashes)" }
  if ($gs.conflicts > 0) { $arr = $arr | append $"~($gs.conflicts)" }

  let staged = (
    $gs.idx_added_staged +
    $gs.idx_modified_staged +
    $gs.idx_deleted_staged +
    $gs.idx_renamed +
    $gs.idx_type_changed
  )
  if ($staged > 0) { $arr = $arr | append $"+($staged)" }

  let unstaged = (
    $gs.wt_modified +
    $gs.wt_deleted +
    $gs.wt_renamed +
    $gs.wt_type_changed
  )
  if ($unstaged > 0) { $arr = $arr | append $"!($unstaged)" }

  if ($gs.wt_untracked > 0) { $arr = $arr | append $"?($gs.wt_untracked)" }

  let res = if (($arr | length) == 0) { "-" } else ($arr | str join " ")

  $" ($res)" | add_color "cyan"
}

def part_cmd_duration [] {
  let dur = (($env.CMD_DURATION_MS | into int) * 1000000) | into duration
  let color = if ($env.LAST_EXIT_CODE == 0) { "green" } else { "red" }
  $"󱦟 ($dur)" | add_color $color
}

def part_time [] {
  let time = date now | format date "%H:%M:%S"
  $"󰅐 ($time)" | add_color "yellow"
}

export def left_prompt [] {
  let gs = gstat
  let parts_left = [ { part_path }, { part_git_branch $gs }, { part_git_status $gs } ]
  let parts_right = [ { part_cmd_duration }, { part_time } ]
  let fill = '-'
  let fill_color = 'dark_gray'
  let line = combine_parts $parts_left $parts_right $fill $fill_color
  (char newline) + $line + (char newline)
}

export def right_prompt [] {
  # TODO: something that is useful during typing command but not in history
  ''
}
