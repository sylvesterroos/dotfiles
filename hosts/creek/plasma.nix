{ pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.wayland.compositor = "kwin";
  services.desktopManager.plasma6.enable = true;

  programs.kdeconnect = {
    enable = true;
  };

  xdg.terminal-exec.enable = true;

  environment.systemPackages = with pkgs.kdePackages; [
    discover
    filelight
    isoimagewriter
    kclock
    partitionmanager
  ];
}
