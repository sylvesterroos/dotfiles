{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.plasma;
in
{
  options.my.plasma = {
    enable = mkEnableOption "KDE Plasma desktop" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.displayManager.sddm.wayland.compositor = "kwin";
    services.desktopManager.plasma6.enable = true;

    programs.kdeconnect = {
      enable = true;
    };

    xdg.terminal-exec.enable = true;

    environment.systemPackages =
      with pkgs.kdePackages;
      [
        discover
        filelight
        isoimagewriter
        kclock
        partitionmanager
      ]
      ++ [
        # partitionmanager only shows filesystems whose mkfs tool is on PATH
        pkgs.exfatprogs
        pkgs.ntfs3g
        pkgs.btrfs-progs
      ];
  };
}
