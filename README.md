# dotfiles

pi and vim config. The repo root is `$HOME`; `.gitignore` is an allowlist, so
only the files it names are tracked.

    git-dir:   ~/.dotfiles    (bare, this repo)
    work-tree: $HOME

No symlinks: pi rewrites its own config files, which silently breaks them.

## Use

`dotfiles <git subcommand>` — a wrapper for
`git --git-dir=$HOME/.dotfiles --work-tree=$HOME`, kept in
`~/.dotfiles.d/bin/dotfiles` and symlinked into `~/.local/bin`.

## New machine

```bash
git clone --bare git@github.com:andr462c/.dotfiles.git ~/.dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
# Resolve conflicts
dotfiles checkout
```
Install vim plug and pi

If `checkout` aborts with *"untracked working tree files would be overwritten"*, it
is refusing to clobber config you already have. Move the named files aside and run
it again:

```bash
mv ~/.vimrc ~/.vimrc.pre-dotfiles
git --git-dir=~/.dotfiles --work-tree=$HOME checkout main
```
