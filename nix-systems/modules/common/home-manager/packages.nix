{pkgs, ...}: {
  home.packages = with pkgs; [
    cachix
    stow
    podman-compose
    pods
    wl-clipboard
    ranger
    findutils
    fd
    neofetch
    onefetch
    nextcloud-client
    figlet # making large letters out of ordinary text
    devenv
    via
    gitleaks
    beam.packages.erlang_27.elixir_1_18
    nil
    radicle-node
    nix-alien
    zotero
    gradia
    discord
    bitwarden-desktop
    spotify
    calibre
    qbittorrent
  ];
}
