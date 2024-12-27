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
  # TODO extract to livebook.nix
  (writeShellApplication {
    name = "livebook";
    runtimeInputs = [
      gcc # some dependencies require compilation
      gnumake
      cmake
      cargo # some dependencies use rustler
    ];
    text = ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${livebook}/bin/livebook "$@"
    '';
  })
  zed-editor
  devenv
  betterdiscordctl
  via
  gitleaks
  magit
  flameshot
  erlang_27 # global erlang for global elixir from mise
  nil # nix lsp
  radicle-node
  ghostty
  nix-alien

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
  gnomeExtensions.rounded-window-corners-reborn
  #gnomeExtensions.solaar-extension
  gnomeExtensions.space-bar
  gnomeExtensions.tactile
]
