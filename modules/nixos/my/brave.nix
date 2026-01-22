{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.brave-browser;
in
{
  options.my.brave-browser = {
    enable = mkEnableOption "brave-browser" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.chromium.enable = true;

    environment.systemPackages = with pkgs; [
      brave
    ];
  };
}
