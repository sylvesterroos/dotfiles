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
      let
        beamPkgs = pkgs.beam.packages.erlang_29;
        erlang = beamPkgs.erlang;
        elixir = beamPkgs.elixir_1_20;
      in
      [
        elixir
        erlang
        cachix
        devenv
        fastfetch
        fd
        figlet # making large letters out of ordinary text
        gitleaks
        mpatch
        nil
        onefetch
        ranger
        stow
        topiary
        upscayl
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        commit
        dbeaver-bin
        gradia
        krusader
        nix-alien
        obsidian
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
