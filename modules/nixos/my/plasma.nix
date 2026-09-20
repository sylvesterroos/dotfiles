{
  lib,
  config,
  pkgs,
  # outputs,
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
      # outputs.overlays.kde-xdg-data-dirs
    ];

    services.displayManager.sddm = {
      enable = true;
      # SDDM 0.21.0 Wayland VT bug (upstream #2129, fix = PR #2204, unmerged) —
      # patched package, see pkgs/sddm-vt-fix. Drop when sddm ships the fix.
      package = mkForce pkgs.sddm-vt-fix;
      wayland.enable = true;
      wayland.compositor = "kwin";
    };
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
