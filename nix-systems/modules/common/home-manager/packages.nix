{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      beam.packages.erlang_28.elixir_1_19
      cachix
      dbeaver-bin
      devenv
      fd
      figlet # making large letters out of ordinary text
      gitleaks
      neofetch
      onefetch
      radicle-node
      ranger
      stow
      zotero
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      bitwarden-desktop
      calibre
      commit
      discord
      gradia
      nextcloud-client
      nix-alien
      podman-compose
      podman-desktop
      podman-tui
      pods
      qbittorrent
      signal-desktop
      spotify
      via
      wl-clipboard
    ];
}
