{ inputs, ... }:
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      services.linux-wallpaperengine.enable = true;

      home.packages = [
        inputs.linux-wallpaper-engine.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
