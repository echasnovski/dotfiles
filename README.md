# Personal dotfiles

This is a Git repository to backup and track dotfiles for Linux OS (Arch-based at the moment but most should work on Ubuntu). Structured for a better use with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is created to be a "stow package": a bundle of files which can be symlinked as a group. To create symlinks for a package (for example, 'bash'), run:

```bash
stow -t ~ -vS bash
```

NOTE: Neovim package is a Git submodule to my [personal Neovim configuration](https://github.com/echasnovski/nvim).

## Used tools

A (probably not full) list of (at least once in a while) used tools (in alphabetical order; asterisk indicates crucial ones):

- [Git](http://git-scm.com/) \*
- [GnuPG](https://gnupg.org/) \*
- [Ipython](https://ipython.org/)
- [Kitty](https://sw.kovidgoyal.net/kitty/binary/#manually-installing)
- [Neovim](https://github.com/neovim/neovim) \*
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) \*
- [RStudio](https://www.rstudio.com/)
- [Stow](https://www.gnu.org/software/stow/) \*
- [VS Code](https://code.visualstudio.com/)
- [Vim](https://www.vim.org/) \*
- [Zsh](https://www.zsh.org/) \*
- [btop](https://github.com/aristocratos/btop)
- [dunst](https://dunst-project.org/)
- [fzf](https://github.com/junegunn/fzf)
- [i3](https://i3wm.org/) \*
- [nnn](https://github.com/jarun/nnn) \*
- [pass](https://www.passwordstore.org/) \*
- [polybar](https://github.com/polybar/polybar) \*
- [radian](https://github.com/randy3k/radian)
- [rofi](https://github.com/davatorium/rofi) \*
- [xfce4-terminal](https://docs.xfce.org/apps/terminal/start)

## Back up

- All personal data.
- `/opt` directories with useful appimages.
- GPG key:
    - Identify your private key: `gpg --list-secret-keys evgeni.chasnovski@gmail.com`. Remember the ID of your key.
    - Export key: `gpg --export-secret-keys YOUR_ID_HERE > private.key`.
    - Copy the key file to the other machine using a secure transport.
- Firefox data: whole '~/.mozilla/firefox' directory.
- Password store of `pass`: whole '~/.password-store'.
- (Optional) Transmission config: whole '~/.config/transmission' config.

## Set up

Approximate guidance steps for Arch-based system:

- Install patched fonts (that support icons). Recommended 'UbuntuMono Nerd Font':
    - Download a [Nerd Font](https://www.nerdfonts.com/).
    - Unzip and copy to '~/.local/share/fonts'.
    - Run the command `fc-cache -fv` to manually rebuild the font cache.

- Install tools:

```bash
sudo pacman -Syu
yay -Syu

sudo pacman -S btop dunst feh fzf git gnupg i3-wm i3lock imagemagick maim openssl pass picom polybar pyenv python-pip r ripgrep rofi stow vim vlc xdotool xfce4-terminal zsh
yay -S pyenv-virtualenv
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
python -m pip install pipx
pipx install ipython pre-commit radian
```

- Clone this repository with its submodules:

```bash
git clone --depth 1 https://github.com/echasnovski/dotfiles ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive --depth 1
```

- Stow dotfiles Run from `~/dotfiles` (something may fail due to some files being auto-created during app installation; remove them):

```bash
stow -t ~ -vS bash btop compton fzf git gpg i3 ipython neovim nnn polybar radian rofi vim wallpapers xfce4 zsh
```

- Restore backup:
  - GPG key: `gpg --import /path/to/private.key`.
  - Copy backed up directories: '~/.mozilla/firefox', '~/.password-store', '~/.config/transmission'.
  - Copy `/opt` subdirectories and mack symbolic links to `/usr/local/bin` (see later general advices).

- Create '~/.profile' with only relevant local environment variables. Like `TERMINAL`, `EDITOR`, `PAGER`, etc. Example:

```bash
export EDITOR=vim
export TERMINAL=xfce4-terminal
```

- Generate wallpaper `png`s. See '~/.wallpapers/tiles/README.md'.
- Tweak polybar temperature sensor. See '~/.config/polybar/config_template.ini' in `[module/temperature]`.
- Set up Neovim. See '~/.config/nvim/README.md'.

## Notes for tools

### General

- Three recommended ways of installing applications:
    - On Arch-based systems use `pacman` (`sudo pacman -S ...`) or `yay` (`yay -S ...`) whenever possible.
    - For extra control use appimages (like several versions of `Neovim`):
      - Put binary in '/opt/<app-name>/<app-binary>' (like '/opt/neovim/nvim_0.6.0').
      - Make it executable with `sudo chmod u+x` (like `sudo chmod u+x /opt/neovim/nvim_0.6.0`).
      - Make soft link to '/usr/local/bin' (like `sudo ln -s /opt/neovim/nvim_0.6.0 /usr/local/bin/nvim`).
    - Use [pipx](https://github.com/pypa/pipx) instead of `pip` to install python-written applications (again, if not on Arch-based systems).

### Kitty

- Image preview requires [imagemagick](https://imagemagick.org/script/download.php). Use appimage.
- Use `kitty +kitten ssh <path>` to make ssh connection. Among other things, it makes `tmux` work.

### Polybar

- Installation:
  - On Arch-based systems use `sudo pacman -S polybar`.
  - On other systems installation might require compilation from source (at least on Ubuntu). Using [official instructions](https://github.com/polybar/polybar/wiki/Compiling) helped.

### nnn

- To enable nerd font icons: clone, make and move to `/usr/local/bin`:

```bash
git clone --depth 1 https://github.com/jarun/nnn
sudo mv nnn /opt
cd /opt/nnn
# Needs basic 'make' prerequisites (see github repo for more details)
sudo make O_NERD=1
sudo ln -s /opt/nnn/nnn /usr/local/bin/nnn
```
