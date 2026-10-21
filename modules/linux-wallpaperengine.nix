{ inputs, ... }:
{
  flake.modules.homeManager.linux-wallpaperengine =
    { pkgs, ... }:
    {
      services.linux-wallpaperengine.enable = true;

      home.packages = [
        inputs.linux-wallpaper-engine.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
