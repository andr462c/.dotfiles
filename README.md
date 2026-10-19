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
git clone --bare git@github.com:andr462c/dotfiles.git ~/.dotfiles
git --git-dir=~/.dotfiles config core.bare false   # must precede --work-tree
git --git-dir=~/.dotfiles --work-tree=$HOME checkout main
chmod +x ~/.dotfiles.d/bin/dotfiles
ln -s ~/.dotfiles.d/bin/dotfiles ~/.local/bin/dotfiles

mkdir -p ~/.vim/undo ~/.vim/backup                 # .vimrc backupdir/undodir
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall

curl -fsSL https://pi.dev/install.sh | sh
pi update --extensions                             # installs the packages in settings.json
cp -n ~/.pi/agent/models.json.example ~/.pi/agent/models.json  # -n keeps an existing file; then set baseUrl
```

If `checkout` aborts with *"untracked working tree files would be overwritten"*, it
is refusing to clobber config you already have. Move the named files aside and run
it again:

```bash
mv ~/.vimrc ~/.vimrc.pre-dotfiles
git --git-dir=~/.dotfiles --work-tree=$HOME checkout main
```
