{ pkgs, ... }:

with pkgs;
[
  nixfmt-rfc-style
  git
  git-lfs
  neovim
  wget
  eza
  ripgrep
  unzip
  logiops
  btop
  bat
  morewaita-icon-theme
  termscp
  jq
  fzf

  ### virtualization ###
  win-virtio
  win-spice
]
