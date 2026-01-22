{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.nix-flatpak;
in
{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  options.my.nix-flatpak = {
    enable = mkEnableOption "nix-flatpak" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.flatpak = mkIf pkgs.stdenv.isLinux {
      enable = true;
      packages = [
        "eu.betterbird.Betterbird"
        "io.github.kelvinnovais.Kasasa"
        "com.github.iwalton3.jellyfin-media-player"
        "org.pgadmin.pgadmin4"
        "com.usebottles.bottles"
      ];

      update.auto = {
        enable = true;
        onCalendar = "daily";
      };

      overrides = {
        "org.pgadmin.pgadmin4".Context = {
          filesystems = [
            "/run/postgresql"
            "/run/user/1000"
          ];
        };
      };
    };
  };
}
