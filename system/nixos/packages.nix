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
  #solaar
  btop
  bat
  morewaita-icon-theme
  termscp
  jq

  ### virtualization ###
  win-virtio
  win-spice
]
