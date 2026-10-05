{
  pkgs,
  lib,
  config,
  inputs,
  mv,
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
        stablePkgs = mv.at (lib.last mv.releases);
      in
      [
        attic-client
        elixir
        erlang
        devenv
        fastfetch
        fd
        figlet # making large letters out of ordinary text
        gitleaks
        godot
        mpatch
        nil
        onefetch
        ranger
        stow
        topiary
        upscayl
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        commit
        dbeaver-bin
        gradia
        krusader
        libreoffice-qt
        nix-alien
        obsidian
        podman-desktop
        podman-tui
        pods
        qbittorrent
        sgdboop
        signal-desktop
        stablePkgs.calibre
        wl-clipboard
        zotero
      ];
  };
}
