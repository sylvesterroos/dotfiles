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

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-software
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.just-perfection
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.pano
    gnomeExtensions.quick-settings-tweaker
    gnomeExtensions.rounded-window-corners-reborn
    gnomeExtensions.space-bar
    gnomeExtensions.tactile
    gnomeExtensions.wiggle
  ];
}
