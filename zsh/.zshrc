# Allow usage of `<C-s>` in Vim/Neovim (disable flow control)
# NOTE: this should be placed before 'p10k-instant-promt' because otherwise it
# throws error about 'standard input' and 'ioctl'
stty -ixon -ixoff

# Set up GnuPG. Should go before 'p10k-instant-promt' because otherwise
# `GPG_TTY` will be `not a tty`.
export GPG_TTY=$(tty)

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

## Use Vi keybindings (should be placed before 'fzf' initialisation for correct
## keybindings)
bindkey -v
bindkey "^?" backward-delete-char

## Change cursor depending on Vi mode (comes from vi-mode plugin)
VI_MODE_SET_CURSOR=true

## The time the shell waits, in hundredths of seconds, for another key
## to be pressed when reading bound multi-character sequences.
##
## Set to a relatively short time.
## This allows escape sequences like cursor/arrow keys to work,
## while eliminating the delay exiting vi insert mode.
KEYTIMEOUT=5

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Source theme
source ~/powerlevel10k/powerlevel10k.zsh-theme

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# User configuration

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--layout=reverse --inline-info --height 25%'

# Add pyenv to PATH
export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# History settings
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt HIST_FIND_NO_DUPS

# Make 'Up' and 'Down' arrows respect search beginning. Other possible values
# which worked previously for binding arrows are "\eOA" and "\eOB"
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias untar='tar -zxvf' # Unpack .tar file

alias pacup='sudo pacman -Syu'
alias paccleanup='sudo pacman -Sc'
alias yayup='yay -Syu'
alias yaycleanup='yay -Sc'

alias lgit='lazygit --git-dir=$(git rev-parse --git-dir) --work-tree=$(realpath .)'

alias videodown='yt-dlp -o "~/Videos/%(uploader)s - %(upload_date)s - %(title)s.%(ext)s" -f "bestvideo[height<=720]+bestaudio/best[height<=720]" -r "100M" --write-sub --sub-lang "en"'

alias rm-nvim-repro='yes | rm -r ~/.local/share/nvim-repro ~/.local/state/nvim-repro'

# Add custom completions
fpath=($ZSH/completions $fpath)
autoload -U compinit && compinit

# Add important directories to PATH
export PATH="$PATH:$HOME/.local/bin"

# NNN file manager
export NNN_PLUG="p:preview-tui"
export NNN_BMS="n:$HOME/.config/nvim;m:$HOME/.config/nvim/pack/plugins/opt/mini"
export NNN_FCOLORS="c1e204020005060203d6ab01"

n ()
{
    # Block nesting of nnn in subshells
    if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # Use `-a` to generate random `NNN_FIFO`
    nnn "$@" -a -A -e -H

    if [ -f "$NNN_TMPFILE" ]; then
        . "$NNN_TMPFILE"
        rm -f "$NNN_TMPFILE" > /dev/null
    fi
}

# Test if the shell is launched in Neovim's terminal
if [[ -n "${NVIM}" ]]
then
  # Unset variables to allow calling `vim` inside Neovim's terminal
  unset VIMRUNTIME VIM
fi

# `rg` config
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/.ripgreprc"

# `z` CLI
. ~/scripts/z/z.sh

export MANPAGER='nvim --clean +Man!'
export PAGER='nvim --clean +Man!'

export GHOSTTY_RESOURCES_DIR="$HOME/.local/share/ghostty/ghostty"
