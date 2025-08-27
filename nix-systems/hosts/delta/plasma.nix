{...}: {
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  hardware.bluetooth.enable = true;

  programs.kdeconnect = {
    enable = true;
  };
}
