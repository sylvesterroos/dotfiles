{ pkgs, ... }:
with pkgs;
[
  stow
  podman-compose
  pods
  xsel
  wl-clipboard
  ranger
  findutils
  fd
  neofetch
  onefetch
  nextcloud-client
  figlet # making large letters out of ordinary text
  mission-center
  livebook
  zed-editor
  devenv
  betterdiscordctl
  via
  gitleaks
  magit
  flameshot
  beam.packages.erlang_27.elixir_1_17
  nixd

  # extra gnome packages
  gnome-tweaks
  gnome-software
  gnome-extension-manager
  gnomeExtensions.alphabetical-app-grid
  gnomeExtensions.appindicator
  gnomeExtensions.blur-my-shell
  gnomeExtensions.dash-to-dock
  gnomeExtensions.just-perfection
  gnomeExtensions.night-theme-switcher
  gnomeExtensions.pano
  gnomeExtensions.quick-settings-tweaker
  gnomeExtensions.rounded-window-corners
  #gnomeExtensions.solaar-extension
  gnomeExtensions.space-bar
  gnomeExtensions.tactile
]
