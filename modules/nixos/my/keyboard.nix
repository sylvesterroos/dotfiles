{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.keyboard;
in
{
  options.my.keyboard = {
    enable = mkEnableOption "keyboard" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.xserver.xkb.variant = "altgr-intl";

    # Required to configure ZSA keyboards using Oryx
    hardware.keyboard.zsa.enable = true;

    # required to configure QMK keyboard as a non-root user
    hardware.keyboard.qmk.enable = true;

    environment.systemPackages = with pkgs; [
      keymapp
      via
    ];
  };
}
