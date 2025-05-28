{ pkgs }:

with pkgs;
[
  cachix
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
  devenv
  betterdiscordctl
  via
  gitleaks
  gitu # git porcelain outside of emacs
  beam.packages.erlang_27.elixir_1_18
  nil
  radicle-node
  radicle-desktop
  nix-alien
  virt-manager
  gnome-boxes
  kdePackages.discover

  valent
  gnomeExtensions.valent

  (import ./livebook.nix { inherit pkgs; })

  # extra gnome packages
  gnome-tweaks
  gnome-software
  # gnome-extension-manager
  gnomeExtensions.alphabetical-app-grid
  gnomeExtensions.appindicator
  gnomeExtensions.blur-my-shell
  gnomeExtensions.dash-to-dock
  gnomeExtensions.just-perfection
  gnomeExtensions.night-theme-switcher
  gnomeExtensions.pano
  gnomeExtensions.quick-settings-tweaker
  gnomeExtensions.rounded-window-corners-reborn
  #gnomeExtensions.solaar-extension
  gnomeExtensions.space-bar
  gnomeExtensions.tactile
  gnomeExtensions.wiggle
]
