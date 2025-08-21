{pkgs, ...}: {
  home.packages = with pkgs; [
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
