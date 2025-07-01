{ pkgs, ... }:

with pkgs;
[
  nixfmt-rfc-style
  git
  git-lfs
  helix
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
  inetutils
  fzf

  ### virtualization ###
  win-virtio
  win-spice
]
