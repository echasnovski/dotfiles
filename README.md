# Personal dotfiles

This is a Git repository to backup and track dotfiles for Linux OS (Arch-based at the moment but most should work on Ubuntu). Structured for a better use with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is created to be a "stow package": a bundle of files which can be symlinked as a group. To create symlinks for a package (for example, 'bash'), run:

```bash
stow -t ~ -vS bash
```

NOTE: Neovim package is a Git submodule to my [personal Neovim configuration](https://github.com/echasnovski/nvim).

## Used tools

A (probably not full) list of (at least once in a while) used tools (in alphabetical order; asterisk indicates crucial ones):

- [btop](https://github.com/aristocratos/btop)
- [dunst](https://dunst-project.org/)
- [fzf](https://github.com/junegunn/fzf)
- [Git](http://git-scm.com/) \*
- [GnuPG](https://gnupg.org/) \*
- [i3](https://i3wm.org/) \*
- [Ipython](https://ipython.org/)
- [Kitty](https://sw.kovidgoyal.net/kitty/binary/#manually-installing)
- [lazygit](https://github.com/jesseduffield/lazygit) \*
- [Neovim](https://github.com/neovim/neovim) \*
- [nnn](https://github.com/jarun/nnn) \*
- [pass](https://www.passwordstore.org/) \*
- [polybar](https://github.com/polybar/polybar) \*
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) \*
- [radian](https://github.com/randy3k/radian)
- [rofi](https://github.com/davatorium/rofi) \*
- [RStudio](https://www.rstudio.com/)
- [Stow](https://www.gnu.org/software/stow/) \*
- [Vim](https://www.vim.org/) \*
- [VS Code](https://code.visualstudio.com/)
- [xfce4-terminal](https://docs.xfce.org/apps/terminal/start)
- [Zathura](https://wiki.archlinux.org/title/Zathura)
- [Zsh](https://www.zsh.org/) \*

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

- Install tools:

```bash
sudo pacman -Syu
yay -Syu

sudo pacman -S acpilight btop dunst fd feh fzf git gnupg i3-wm i3lock imagemagick lazygit maim mupdf openssl pass picom polybar pyenv python-pip r ripgrep rofi stow vim vlc xdotool xfce4-terminal xsel zathura zathura-djvu zathura-pdf-mupdf zsh
yay -S pyenv-virtualenv skypeforlinux-stable-bin visual-studio-code-bin pandoc-bin
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
python -m pip install pipx

# Manually install `nnn` with Nerd font support (see `nnn` section later)

# After pipx is in PATH
pipx install ipython pre-commit radian
pipx install pre-commit
pipx install radian
```

- Clone this repository with its submodules:

```bash
git clone --depth 1 https://github.com/echasnovski/dotfiles ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive --depth 1
```

- Stow dotfiles Run from `~/dotfiles` (something may fail due to some files being auto-created during app installation; remove them):

```bash
stow -t ~ -vS bash btop dunst fonts fzf git gpg i3 ipython lazygit neovim nnn picom polybar r radian ripgrep rofi st vim wallpapers xfce4 xorg zathura zsh
```

- Enable fonts with `fc-cache -fv`.

- Restore backup:
  - GPG key: `gpg --import /path/to/private.key`.
  - Copy backed up directories: '~/.mozilla/firefox', '~/.password-store', '~/.config/transmission'.
  - Copy `/opt` subdirectories and make symbolic links to `/usr/local/bin` (see later general advices).

- Create '~/.profile' with only relevant local environment variables. Like `TERMINAL`, `EDITOR`, `PAGER`, etc. Example:

```bash
export EDITOR=vim
export TERMINAL=st
export DPI=168
```

- Tweak DPI. For that:
    - Update '~/.Xresources' with `Xft.dpi: <value>`. Helpful additional configuration:
      ```
      ! Adjust DPI with additional rendering instructions
      Xft.dpi: 168
      Xft.autohint: 0
      Xft.lcdfilter:  lcddefault
      Xft.hintstyle:  hintfull
      Xft.hinting: 1
      Xft.antialias: 1
      Xft.rgba: rgb
      ```
- Install `st` from source. Go to `~/st` and run `sudo make install`, which will install it system-wide in '/usr/local' directory (configured in 'config.mk'). Building it might require installation of special "building" software.

- Change default shell: `chsh -s $(which zsh)` (takes effect after logout).

- Generate wallpaper `png`s. See '~/.wallpapers/tiles/README.md'.

- Tweak polybar sources. See header of '~/.config/polybar/config_template.ini'.

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

### st

Whole source code for "simple terminal" is shipped with these dotfiles in 'st' directory ('~/st' after applying `stow`). Build and install system-wide from that source.

### Kitty

- Image preview requires [imagemagick](https://imagemagick.org/script/download.php). Use appimage.
- Use `kitty +kitten ssh <path>` to make ssh connection. Among other things, it makes `tmux` work.

### Xfce4 terminal

- To remove border around opened apps, update '~/.config/gtk-3.0/gtk.css' with:
```
VteTerminal, vte-terminal {
  padding: 0px;
}
```

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
