{
  lib,
  config,
  pkgs,
  outputs,
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
    nixpkgs.overlays = [
      outputs.overlays.kde-xdg-data-dirs
    ];

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
        kcalc
        kcolorchooser
        partitionmanager
      ]
      ++ (with pkgs; [
        # partitionmanager only shows filesystems whose mkfs tool is on PATH
        exfatprogs
        ntfs3g
        btrfs-progs

        haruna
      ]);
  };
}
