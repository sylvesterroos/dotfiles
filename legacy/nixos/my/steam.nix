{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.steam;
in
{
  options.my.steam = {
    enable = mkEnableOption "Steam";
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
      remotePlay.openFirewall = true;
      protontricks.enable = true;
    };

    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

    environment.systemPackages = with pkgs; [
      mangohud
      mangojuice
    ];
  };
}
