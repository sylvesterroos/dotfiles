{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.discord;
in
{
  options.my.discord = {
    enable = mkEnableOption "discord" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (discord.override {
        withOpenASAR = false;
        withVencord = true;
      })
    ];
  };
}
