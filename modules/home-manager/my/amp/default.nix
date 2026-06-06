{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.amp;
in
{
  options.my.amp = {
    enable = mkEnableOption "amp" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      amp-cli
    ];
  };
}
