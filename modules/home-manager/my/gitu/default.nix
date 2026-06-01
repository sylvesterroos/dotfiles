{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.gitu;
in
{
  options.my.gitu = {
    enable = mkEnableOption "gitu" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gitu
    ];

    home.file.".config/gitu/config.toml".source = ./config.toml;
  };
}
