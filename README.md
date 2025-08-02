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
nh os switch --update

# or

nix flake update --commit-lock-file --flake $HOME/.dotfiles/system
```

To rebuild the system, run:
```sh
nh os switch --hostname my_hostname
```

#### Home Manager

To switch your user profile with Home Manager, use:

```sh
nh home switch
```
