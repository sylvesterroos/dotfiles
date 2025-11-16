{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    packages = [
      "eu.betterbird.Betterbird"
      "io.github.kelvinnovais.Kasasa"
      "com.github.iwalton3.jellyfin-media-player"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };
}
