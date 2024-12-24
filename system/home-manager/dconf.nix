{ lib, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings" = {
      # Alt+F4 is a terrible keybind
      close = [ "<Shift><Super>q" ];

      # Full-screen with title/navigation bar
      toggle-fullscreen = [ "<Shift>F11" ];
    };

    "org/gnome/desktop/input-sources" = {
      # leave out "terminate:ctrl_alt_bksp" to fix ctrl-backspace in certain gnome apps
      xkb-options = [
        "caps:escape" # caps -> esc
      ];
    };

    # Use 6 fixed workspaces instead of dynamic mode
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 6;
    };

    # Use alt for pinned apps
    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ "<Alt>1" ];
      switch-to-application-2 = [ "<Alt>2" ];
      switch-to-application-3 = [ "<Alt>3" ];
      switch-to-application-4 = [ "<Alt>4" ];
      switch-to-application-5 = [ "<Alt>5" ];
      switch-to-application-6 = [ "<Alt>6" ];
      switch-to-application-7 = [ "<Alt>7" ];
      switch-to-application-8 = [ "<Alt>8" ];
      switch-to-application-9 = [ "<Alt>9" ];
    };

    # Use super for workspaces
    "org/gnome/desktop/wm/keybindings" = {
      # empty lists to let spacebar handle this behavior
      switch-to-workspace-1 = [
        # "<Super>1"
        "<Super>Home"
      ];
      switch-to-workspace-2 = [
        # "<Super>2"
      ];
      switch-to-workspace-3 = [
        # "<Super>3"
      ];
      switch-to-workspace-4 = [
        # "<Super>4"
      ];
      switch-to-workspace-5 = [
        # "<Super>5"
      ];
      switch-to-workspace-6 = [
        # "<Super>6"
      ];
    };

    # Move windows to specific workspaces
    "org/gnome/desktop/wm/keybindings" = {
      move-to-workspace-1 = [
        "<Shift><Super>1"
        "<Shift><Super>Home"
      ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      move-to-workspace-5 = [ "<Shift><Super>5" ];
      move-to-workspace-6 = [ "<Shift><Super>6" ];
    };

    # Set flameshot (with the fix for starting under Wayland) on alternate print screen key
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control>Print";
      command = "script --command 'flameshot gui' /dev/null";
      name = "Flameshot";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Control><Super>space";
      command = "flatpak run it.mijorus.smile";
      name = "Smile emoji picker";
    };

    # Configure tactile
    "org/gnome/shell/extensions/tactile" = {
      col-0 = 1;
      row-0 = 1;
      col-1 = 2;
      col-2 = 1;
      col-3 = 0;
      row-1 = 1;
      row-2 = 0;
      gap-size = 32;
    };

    # Configure just-perfection
    "org/gnome/shell/extensions/just-perfection" = {
      animation = 5;
    };

    # Configure blur-my-shell
    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      blur = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      blur = false;
    };
    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      blur = false;
      pipeline = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      blur = false;
      brightness = 0.6;
      sigma = 30;
    };
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = false;
      pipeline = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
    };
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.6;
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
    };

    # Configure space-bar
    "org/gnome/shell/extensions/space-bar/behavior" = {
      smart-workspace-names = false;
      toggle-overview = false;
      scroll-wheel = "disabled";
    };
    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = true;
      back-and-forth = true;
      enable-move-to-workspace-shortcuts = false; # handled already
      open-menu = [ ];
      move-workspace-left = [ ];
      move-workspace-right = [ ];
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

    # easy access to "Large Text" for HiDPI screens
    "org/gnome/desktop/a11y" = {
      always-show-universal-access-status = true;
    };

    # gnome tweaks
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,close";
      focus-mode = "sloppy";
      resize-with-right-button = true;
    };

    "org/gnome/desktop/interface" = {
      # macos-like fonts
      # https://x.com/luciascarlet/status/1857965489424589000
      font-hinting = "none";
    };
  };
}
