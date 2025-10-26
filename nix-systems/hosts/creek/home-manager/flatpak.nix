{inputs, ...}: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = {
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
