# Personal dotfiles

This is a Git repository to backup and track dotfiles. Structured for a better use with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is created to be a "stow package": a bundle of files which can be symlinked as a group. To create symlinks for a package (for example, 'bash'), run:

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
- [Oh My Zsh](https://ohmyz.sh/) \*
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) \*
- [RStudio](https://www.rstudio.com/)
- [Stow](https://www.gnu.org/software/stow/) \*
- [VS Code](https://code.visualstudio.com/)
- [Vim](https://www.vim.org/) \*
- [Zsh](https://www.zsh.org/) \*
- [btop](https://github.com/aristocratos/btop)
- [fzf](https://github.com/junegunn/fzf)
- [i3](https://i3wm.org/) \*
- [pass](https://www.passwordstore.org/) \*
- [radian](https://github.com/randy3k/radian)
- [ranger](https://github.com/ranger/ranger) \*
- [rofi](https://github.com/davatorium/rofi) \*

## Notes for tools

### General

- Current general recommendation for installing applications is to prefer binary `appimage` (like with `Neovim`, `Kitty`, `btop`, etc.):
    - Put binary in '/opt/<app-name>/<app-binary>' (like '/opt/neovim/nvim_0.6.0').
    - Make it executable with `sudo chmod u+x` (like `sudo chmod u+x /opt/neovim/nvim_0.6.0`).
    - Make soft link to '/usr/local/bin' (like `sudo ln -s /opt/neovim/nvim_0.6.0 /usr/local/bin/nvim`).
- Prefer [pipx](https://github.com/pypa/pipx) for installation python-written applications (like `radian`, `ranger` with `ranger-fm`).

### Kitty

- Image preview requires [imagemagick](https://imagemagick.org/script/download.php). Use appimage.
- Use `kitty +kitten ssh <path>` to make ssh connection. Among other things, it makes `tmux` work.

### ranger

- To support image preview with kitty, add `pillow` package: `pipx inject ranger-fm pillow`.
