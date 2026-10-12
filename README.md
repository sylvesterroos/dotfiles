# Dotfiles

My dotfiles

## Stow

From the root of the dotfiles clone, symlink config files to the home directory:

```sh
stow --dir ./home/sylvester --target "$HOME" .
```
