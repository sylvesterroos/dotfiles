{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.home-manager-packages;
in
{
  options.my.home-manager-packages = {
    enable = mkEnableOption "home-manager-packages" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        amp-cli
        beam.packages.erlang_28.elixir_1_19
        cachix
        devenv
        fd
        figlet # making large letters out of ordinary text
        gitleaks
        mpatch
        fastfetch
        nil
        onefetch
        ranger
        stow
        topiary
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        bitwarden-desktop
        commit
        dbeaver-bin
        discord
        gradia
        nextcloud-client
        nix-alien
        obsidian
        podman-compose
        podman-desktop
        podman-tui
        pods
        qbittorrent
        sgdboop
        signal-desktop
        spotify
        stable.calibre
        wl-clipboard
        zotero
      ];
  };
}
