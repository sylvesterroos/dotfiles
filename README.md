# Dotfiles

## Basic usage

Everything starts from the `~/.dotfiles` directory. Make sure to clone this repository to that directory:

```sh
git clone https://gitlab.com/sylvesterroos/dotfiles.git ~/.dotfiles
```

### GNU Stow

Let Stow create the symbolic links from the dotfiles directory to the equivalent structure in the home directory by using:

```sh
stow --dir=$HOME/.dotfiles --target=$HOME/ .
```

If your current directory is `~/.dotfiles` you can simply run:

```sh
stow .
```

#### Ignoring files and directories

To ignore certain files or directories when using Stow, you can add matching regular expressions or strings to the `.stow-local-ignore` file. This means that these files or directories will not be symbolically linked when you run the `stow` command.

### NixOS

The configuration file contained in the `~/.dotfiles` directory is not known by the `nixos-rebuild` command. To fix this you should do one of the following:
- Symlink `configuration.nix` to `/etc/nixos/`
- Or, run `nixos-rebuild -I nixos-config=$HOME/.dotfiles/configuration.nix` instead of `nixos-rebuild`
