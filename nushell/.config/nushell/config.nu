# General =====================================================================
$env.config.show_banner = false
$env.config.bracketed_paste = true

# Table view
$env.config.table.mode = 'reinforced'
$env.config.table.header_on_separator = true
$env.config.table.missing_value_symbol = '×'

# Vi mode =====================================================================
$env.config.edit_mode = 'vi'
$env.config.cursor_shape.vi_insert = 'line'
$env.config.cursor_shape.vi_normal = 'blink_block'

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
$env.XDG_DATA_HOME = $nu.home-path | path join '.local/share'
$env.XDG_STATE_HOME = $nu.home-path | path join '.local/state'
$env.XDG_CACHE_HOME = $nu.home-path | path join '.cache'

# Pager
$env.MANPAGER = 'nvim --clean +Man!'
$env.PAGER = 'nvim --clean +Man!'

# `rg` config
$env.RIPGREP_CONFIG_PATH = $nu.home-path | path join '.config/ripgrep/.ripgreprc'

# Ghostty config
$env.GHOSTTY_RESOURCES_DIR = '~/.local/share/ghostty/ghostty'

# GnuPG
$env.GPG_TTY = $'(tty)'

# Prompt ======================================================================
plugin add nu_plugin_gstat
use ($nu.default-config-dir | path join "prompt.nu") [left_prompt right_prompt]

$env.PROMPT_COMMAND = { left_prompt }
$env.PROMPT_COMMAND_RIGHT = { right_prompt }
$env.PROMPT_INDICATOR = '> '
$env.PROMPT_INDICATOR_VI_NORMAL = '< '
$env.PROMPT_INDICATOR_VI_INSERT = '> '
$env.PROMPT_MULTILINE_INDICATOR = ': '
$env.config.render_right_prompt_on_last_line = true

$env.TRANSIENT_PROMPT_COMMAND = { left_prompt }
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ''
$env.TRANSIENT_PROMPT_INDICATOR = '> '
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = '> '
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = '> '
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = ''

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
$env.NNN_BMS = 'n:$HOME/.config/nvim;m:$HOME/.loca/share/site/nvim/pack/deps/start/mini.nvim'
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

def nvim_pick --env [] {
  let out_path = '/tmp/nvim/out-file'
  nvim --noplugin -u ~/.config/nvim/init-cli-pick.lua -c $"lua _G.pick_file_cli\('($out_path)'\)"

  if ($out_path | path exists) {
    let text = open $out_path | str trim | str replace "\n" " "
    rm -p $out_path
    commandline edit --insert $text
  }
}

$env.config.keybindings ++= [
  {
    name: clear_line
    modifier: control
    keycode: char_t
    mode: vi_insert
    event: { send: executehostcommand, cmd: nvim_pick }
  }
]
