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

To update the system, run:
```sh
nix flake update --commit-lock-file $HOME/.dotfiles/system

# or make use of the included abbreviation
update
```

To rebuild the system, run:
```sh
sudo nixos-rebuild --flake path:$HOME/.dotfiles/system#odysseus switch

# or make use of the included abbreviation
rebuild switch
```

> **NOTE**
>
> Abbreviations, unlike aliases, get expanded to the full command.
