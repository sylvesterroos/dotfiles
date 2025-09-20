{inputs, ...}: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = {
    enable = true;
    packages = [
      # TODO: add "eu.betterbird.Betterbird"
      "io.github.kelvinnovais.Kasasa"
    ];
    update.auto = {
      enable = true;
      onCalendar = "daily";
    };
  };
}
