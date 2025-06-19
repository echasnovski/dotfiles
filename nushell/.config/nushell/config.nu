# General =====================================================================
$env.config.show_banner = false
$env.config.bracketed_paste = true

# Table view
$env.config.table.mode = 'compact_double'
$env.config.table.header_on_separator = true
$env.config.table.missing_value_symbol = '×'
$env.config.table.trim = { methodology: "truncating", truncating_suffix: "…" }

$env.config.datetime_format.table = "%Y-%m-%d %H:%M:%S"
$env.config.datetime_format.normal = "%Y-%m-%d %H:%M:%S"

$env.config.completions.algorithm = "fuzzy"

# Vi mode =====================================================================
$env.config.edit_mode = 'vi'
$env.config.cursor_shape.vi_insert = 'line'
$env.config.cursor_shape.vi_normal = 'block'

$env.config.keybindings ++= [
  {
    name: clear_line
    modifier: control
    keycode: char_u
    mode: vi_insert
    event: { edit: CutFromStart }
  },
  {
    name: history_hint_complete
    modifier: control
    keycode: char_f
    mode: vi_insert
    event: { send: HistoryHintComplete }
  },
  {
    name: history_hint_word_complete
    modifier: alt
    keycode: char_f
    mode: vi_insert
    event: { send: HistoryHintWordComplete }
  },
]

# Environment variables =======================================================
$env.EDITOR = 'vim'

# PATH
$env.PATH = $env.PATH | prepend ['~/.local/bin']

# XDG_***
$env.XDG_CONFIG_HOME = $nu.home-path | path join '.config'
$env.XDG_DATA_HOME = $nu.home-path | path join '.local' 'share'
$env.XDG_STATE_HOME = $nu.home-path | path join '.local' 'state'
$env.XDG_CACHE_HOME = $nu.home-path | path join '.cache'

# Pager
$env.MANPAGER = 'nvim --clean +Man!'
$env.PAGER = 'nvim --clean +Man!'

# `rg` config
$env.RIPGREP_CONFIG_PATH = $nu.home-path | path join '.config/ripgrep/.ripgreprc'

# Ghostty config
$env.GHOSTTY_RESOURCES_DIR = $env.XDG_DATA_HOME | path join 'ghostty' 'ghostty'

# GnuPG
$env.GPG_TTY = $'(tty)'

# Prompt ======================================================================
plugin add nu_plugin_gstat

use ($nu.default-config-dir | path join "prompt2.nu") *

let prompt_parts = [
  # Think about making it work. Right now it results in extra ' ' and affects
  # the overall budget during part combination. Ideally it should start just
  # add an empty line before the full prompt.
  # {part: {(char newline)}, priority : infinity}

  (prompt_part_pwd --priority infinity --trunc_char $"(ansi white_dimmed)…"),
  (prompt_part_gitbranch --priority 4),
  (prompt_part_gitstatus --priority 0),
  (prompt_part_fill --char '╌'),
  (prompt_part_cmdduration --priority 1),
  (prompt_part_time --priority 2),
]
let prompt = $prompt_parts | prompt_make

def make_prompt_indicator [char: string]: nothing -> string {
  (ansi green_bold) + $char + (ansi reset) + ' '
}

$env.PROMPT_COMMAND = $prompt
$env.PROMPT_COMMAND_RIGHT = ''
$env.PROMPT_INDICATOR = make_prompt_indicator '>'
$env.PROMPT_INDICATOR_VI_INSERT = make_prompt_indicator '>'
$env.PROMPT_INDICATOR_VI_NORMAL = make_prompt_indicator '<'
$env.PROMPT_MULTILINE_INDICATOR = make_prompt_indicator ':'
$env.config.render_right_prompt_on_last_line = true

$env.TRANSIENT_PROMPT_COMMAND = $prompt
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ''
$env.TRANSIENT_PROMPT_INDICATOR = ''
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = (ansi default) + '> '
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ''
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = ''

# Theme =======================================================================
source ($nu.default-config-dir | path join "theme.nu")

# Completions =================================================================
source ($nu.default-config-dir | path join "completion-git.nu")
source ($nu.default-config-dir | path join "completion-make.nu")

# Aliases =====================================================================
alias paccleanup = sudo pacman -Sc
alias yaycleanup = yay -Sc

alias lgit = lazygit $'--git-dir=(git rev-parse --git-dir)' $'--work-tree=(realpath .)'

alias videodown = yt-dlp -o '~/Videos/%(uploader)s - %(upload_date)s - %(title)s.%(ext)s' -f 'bestvideo[height<=720]+bestaudio/best[height<=720]' -r '100M' --write-sub --sub-lang 'en'

alias rm-nvim-repro = rm -r ~/.local/share/nvim-repro ~/.local/state/nvim-repro
alias rm-nvim-pack-demo = rm -r ~/.local/share/nvim-pack-demo ~/.local/state/nvim-pack-demo

# NNN file manager ============================================================
$env.NNN_PLUG = 'p:preview-tui'
$env.NNN_BMS = [
  $'n:($env.XDG_CONFIG_HOME)/nvim'
  $'m:($env.XDG_DATA_HOME)/nvim/site/pack/deps/start/mini.nvim'
] | str join ';'
$env.NNN_FCOLORS = 'c1e204020005060203d6ab01'

# Run `nnn` with useful flags. Press `<C-g>` to change working directory to the
# currently displayed in `nnn`.
def n --env [] {
  # Compute file path `nnn` uses to write the command for `<C-g>`
  let nnn_tmpfile = $env.XDG_CONFIG_HOME | path join 'nnn/.lastd'

  # Use `-a` to generate random `NNN_FIFO`
  ^nnn -a -A -e -H

  if ($nnn_tmpfile | path exists) {
    let path = open $nnn_tmpfile
      # Remove <cd '> from the first part of the string and the last single quote <'>.
      | str replace --all --regex `^cd '|'$` ``
      # Fix post-processing of nnn's given path that escapes its single quotes with POSIX syntax.
      | str replace --all `'\''` `'`

    # Delete file to not change working directory on next calls
    ^rm -- $nnn_tmpfile
    cd $path
  }
}

# Neovim ======================================================================
def pull_nvim_nightly [] {
  cp ~/.local/bin/nvim_new ~/.local/bin/nvim_new_prev
  wget -O ~/.local/bin/nvim_new https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
  chmod u+x ~/.local/bin/nvim_new
}

def nvim_pick [command: string] {
  let out_path = '/tmp/nvim/out-file'

  nvim --noplugin -u ~/.config/nvim/init-cli-pick.lua -c $command

  if ($out_path | path exists) {
    let text = open $out_path | str trim | str replace "\n" " "
    rm -p $out_path
    commandline edit --insert $text
  }
}

def nvim_pick_files [] { nvim_pick "lua _G.pick_file_cli()" }

def nvim_pick_dirs [] { nvim_pick "lua _G.pick_dir_cli()" }

def nvim_pick_input []: list -> list {
  let in_path = '/tmp/nvim/in-file'
  let out_path = '/tmp/nvim/out-file'

  mkdir ($in_path | path dirname)
  $in | save $in_path

  nvim --noplugin -u ~/.config/nvim/init-cli-pick.lua -c "lua _G.pick_from_file()"

  rm -p $in_path
  if ($out_path | path exists) {
    let res = open $out_path | str trim | split row "\n"
    rm -p $out_path
    return $res
  }
  return []
}

$env.config.keybindings ++= [
  {
    name: clear_line
    modifier: control
    keycode: char_t
    mode: vi_insert
    event: { send: executehostcommand, cmd: nvim_pick_files }
  },
  {
    name: clear_line
    modifier: control
    keycode: char_d
    mode: vi_insert
    event: { send: executehostcommand, cmd: nvim_pick_dirs }
  }
]
