{ inputs, ... }:
{
  flake.modules.nixos.desktop = {
    services.flatpak.enable = true;
  };

  flake.modules.homeManager.desktop = {
    imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;
      packages = [
        "com.spotify.Client"
        "com.usebottles.bottles"
        "eu.betterbird.Betterbird"
        "io.github.kelvinnovais.Kasasa"
        "org.pgadmin.pgadmin4"
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
