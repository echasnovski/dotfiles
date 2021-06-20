# Personal dotfiles

This is a Git repository to backup and track dotfiles. Structured for a better use with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is created to be a "stow package": a bundle of files which can be symlinked as a group. To create symlinks for a package (for example, 'bash'), run:

```bash
stow -t ~ -vS bash
```

NOTE: Neovim package is a Git submodule to my [personal Neovim configuration](https://github.com/echasnovski/nvim).

## Used tools

A (probably not full) list of (at least once in a while) used tools (in alphabetical order; asterisk indicates crucial ones):

- [Alacritty](https://github.com/alacritty/alacritty) (currently [not supports undercurls](https://github.com/alacritty/alacritty/issues/1628), which is why basic Gnome Terminal is better)
- [Git](http://git-scm.com/) \*
- [GnuPG](https://gnupg.org/) \*
- [Ipython](https://ipython.org/)
- [Neovim](https://github.com/neovim/neovim) \*
- [Oh My Zsh](https://ohmyz.sh/) \*
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) \*
- [RStudio](https://www.rstudio.com/)
- [Stow](https://www.gnu.org/software/stow/) \*
- [VS Code](https://code.visualstudio.com/)
- [Vim](https://www.vim.org/) \*
- [Zsh](https://www.zsh.org/) \*
- [pass](https://www.passwordstore.org/) \*
- [radian](https://github.com/randy3k/radian)
- [ranger](https://github.com/ranger/ranger) \*
