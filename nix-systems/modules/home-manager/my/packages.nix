{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.my.packages;
in {
  options.my.packages = {
    enable =
      mkEnableOption "packages"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
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
        wl-clipboard
      ];
  };
}
