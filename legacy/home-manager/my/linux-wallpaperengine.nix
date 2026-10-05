{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib;
let
  cfg = config.my.linux-wallpaperengine;
in
{
  options.my.linux-wallpaperengine = {
    enable = mkEnableOption "linux-wallpaperengine" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.linux-wallpaperengine.enable = true;

    home.packages = [
      inputs.linux-wallpaper-engine.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
