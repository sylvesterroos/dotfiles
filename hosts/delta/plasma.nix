{ pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.wayland.compositor = "kwin";
  services.desktopManager.plasma6.enable = true;

  hardware.bluetooth.enable = true;

  programs.kdeconnect = {
    enable = true;
  };

  environment.systemPackages = with pkgs.kdePackages; [
    filelight
    kclock
  ];
}
