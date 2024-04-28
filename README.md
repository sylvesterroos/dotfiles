# Dotfiles

## Basic usage

Everything starts from the `~/.dotfiles` directory. Make sure to clone this repository to that directory

### GNU Stow

Let Stow create the symbolic links from this directory to the equivalent structure in the home directory by using:

```sh
stow .
```

Running this inside the `~/.dotfiles` directory is equivalent to running:

```sh
stow --dir=~/.dotfiles --target=~/
```

#### Ignoring files and directories

To ignore certain files or directories when using Stow, you can add matching regular expressions or strings to the `.stow-local-ignore` file. This means that these files or directories will not be symbolically linked when you run the `stow` command.

### NixOS

Symlink `configuration.nix` and `hardware-configuration.nix` to `/etc/nixos/`
