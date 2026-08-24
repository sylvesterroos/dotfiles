{
  config,
  lib,
  inputs,
  outputs,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.plasma;
in
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  options.my.plasma = {
    enable = mkEnableOption "plasma desktop settings" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    programs.plasma = {
      enable = true;

      #
      # Some high-level settings:
      #
      # workspace = {
      #   clickItemTo = "select";
      #   lookAndFeel = "org.kde.breezedark.desktop";
      #   cursor.theme = "Bibata-Modern-Ice";
      #   iconTheme = "Papirus-Dark";
      #   wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
      # };

      # hotkeys.commands."launch-konsole" = {
      #   name = "Launch Konsole";
      #   key = "Meta+Alt+K";
      #   command = "konsole";
      # };

      # panels = [
      #   # Windows-like panel at the bottom
      #   {
      #     location = "bottom";
      #     widgets = [
      #       "org.kde.plasma.kickoff"
      #       "org.kde.plasma.icontasks"
      #       "org.kde.plasma.marginsseparator"
      #       "org.kde.plasma.systemtray"
      #       "org.kde.plasma.digitalclock"
      #     ];
      #   }
      #   # Global menu at the top
      #   {
      #     location = "top";
      #     height = 26;
      #     widgets = [ "org.kde.plasma.appmenu" ];
      #   }
      # ];

      #
      # Some mid-level settings:
      #
      shortcuts = {
        kwin = {
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
          "Switch to Desktop 5" = "Meta+5";
          "Switch to Desktop 6" = "Meta+6";
          "Switch to Desktop 7" = "Meta+7";
          "Switch to Previously Used Desktop" = "Meta+Z";
          "Window to Desktop 1" = "Meta+!";
          "Window to Desktop 2" = "Meta+@";
          "Window to Desktop 3" = "Meta+#";
          "Window to Desktop 4" = "Meta+$";
          "Window to Desktop 5" = "Meta+%";
          "Window to Desktop 6" = "Meta+^";
          "Window to Desktop 7" = "Meta+&";

          "Window One Screen Up" = "Meta+Shift+Up";
          "Window One Screen Down" = "Meta+Shift+Down";
          "Window One Screen to the Left" = "Meta+Shift+Left";
          "Window One Screen to the Right" = "Meta+Shift+Right";
          "Window to Next Screen" = "none";
          "Window to Previous Screen" = "none";

          # Present windows of the current application.
          "ExposeClass" = "Meta+F7";
        };

        plasmashell = {
          "activate task manager entry 1" = "none";
          "activate task manager entry 2" = "none";
          "activate task manager entry 3" = "none";
          "activate task manager entry 4" = "none";
          "activate task manager entry 5" = "none";
          "activate task manager entry 6" = "none";
          "activate task manager entry 7" = "none";
        };
      };

      configFile."kwinrc"."Plugins"."switch-to-previous-desktopEnabled" = true;

      #
      # Some low-level settings:
      #
      # configFile = {
      #   "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
      #   "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "SF";
      #   "kwinrc"."Desktops"."Number" = {
      #     value = 8;
      #     # Forces kde to not change this value (even through the settings app).
      #     immutable = true;
      #   };
      # };
    };

    home.packages = [
      outputs.packages.${pkgs.stdenv.hostPlatform.system}.switch-to-previous-desktop
    ];
  };
}
