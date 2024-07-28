{ lib, ... }:
{
  "org/gnome/desktop/search-providers" = {
    disabled = [
      "org.gnome.Epiphany.desktop"
      "org.gnome.Photos.desktop"
      "org.gnome.clocks.desktop"
    ];
    enabled = [
      "com.github.hugolabe.Wike.desktop"
      "org.gnome.gitlab.cheywood.Iotas.desktop"
    ];
    sort-order = [
      "org.gnome.Documents.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Calculator.desktop"
      "org.gnome.Calendar.desktop"
      "org.gnome.gitlab.cheywood.Iotas.desktop"
      "org.gnome.Characters.desktop"
      "org.gnome.Contacts.desktop"
      "org.gnome.clocks.desktop"
      "app.drey.Dialect.desktop"
      "com.github.finefindus.eyedropper.desktop"
      "org.gnome.seahorse.Application.desktop"
      "org.gnome.Settings.desktop"
      "org.gnome.Epiphany.desktop"
      "com.github.hugolabe.Wike.desktop"
      "org.gnome.Software.desktop"
    ];
  };

  "org/gnome/desktop/interface" = {
    enable-hot-corners = false;
    font-antialiasing = "rgba";
    show-battery-percentage = true;
    monospace-font-name = "JetBrainsMono Nerd Font 10";
    clock-show-weekday = true;
  };

  "org/gnome/mutter" = {
    center-new-windows = true; # gnome tweaks
    dynamic-workspaces = true;
    workspaces-only-on-primary = true;
    edge-tiling = true;
  };

  "org/gnome/system/location" = {
    enabled = true;
  };

  "org/gnome/desktop/privacy" = {
    old-files-age = lib.hm.gvariant.mkUint32 30;
    recent-files-max-age = -1;
    remove-old-temp-files = true;
    remove-old-trash-files = true;
  };

  "org/gnome/settings-daemon/plugins/power" = {
    sleep-inactive-ac-type = "nothing";
  };

  "org/gnome/desktop/peripherals/touchpad" = {
    speed = 0.22;
    tap-to-click = true;
    two-finger-scrolling-enabled = true;
  };

  "org/gnome/desktop/wm/keybindings" = {
    close = [ "<Shift><Super>q" ];
  };

  "org/gnome/desktop/a11y" = {
    always-show-universal-access-status = true;
  };

  "org/freedesktop/tracker/miner/files" = {
    index-recursive-directories = [
      "&DESKTOP"
      "&MUSIC"
      "&PICTURES"
      "&VIDEOS"
      "&DOCUMENTS"
      "/home/sylvester/files"
      "/home/sylvester/Backups"
    ];
  };

  # gnome tweaks
  "org/gnome/desktop/wm/preferences" = {
    button-layout = "appmenu:minimize,close";
    focus-mode = "sloppy";
    resize-with-right-button = true;
  };
}
