{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # remove some default packages
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    evince
    geary
    gnome-maps
    gnome-music
    gnome-weather
    seahorse
    totem
  ];

  services.gnome.gnome-browser-connector.enable = true;

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
}
