{ inputs, ... }:
{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        # outputs.overlays.kde-xdg-data-dirs
      ];

      services.displayManager.plasma-login-manager.enable = true;
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
          keepsecret
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

  flake.modules.homeManager.desktop =
    { lib, pkgs, ... }:
    {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      programs.plasma = {
        enable = true;

        input.keyboard.layouts = [
          {
            layout = "us";
            variant = "altgr-intl";
          }
        ];

        kwin.virtualDesktops.number = lib.mkDefault 6;

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

        # 9 is KWin's ElectricNone: no hot corner for the overview.
        configFile."kwinrc"."Effect-overview"."BorderActivate" = 9;

        # Search results show applications, files and settings; visited websites stay in the browser.
        configFile."krunnerrc"."Plugins"."browserhistoryEnabled" = false;

        # Baloo reads "exclude filters" as the complete list of skipped file and folder names.
        # It opens with Baloo 6.31's defaults (src/file/fileexcludefilters.cpp, list version 9)
        # and adds build output: Mix (_build, deps), Cargo (target) and JS bundlers (dist).
        configFile."baloofilerc"."General" = {
          "exclude filters" = lib.concatStringsSep "," [
            "*~"
            "*.part"
            "*.o"
            "*.la"
            "*.lo"
            "*.loT"
            "*.moc"
            "moc_*.cpp"
            "qrc_*.cpp"
            "ui_*.h"
            "cmake_install.cmake"
            "CMakeCache.txt"
            "CTestTestfile.cmake"
            "libtool"
            "config.status"
            "confdefs.h"
            "autom4te"
            "conftest"
            "confstat"
            "Makefile.am"
            "*.gcode"
            ".ninja_deps"
            ".ninja_log"
            "build.ninja"
            "*.csproj"
            "*.m4"
            "*.rej"
            "*.gmo"
            "*.pc"
            "*.omf"
            "*.aux"
            "*.tmp"
            "*.po"
            "*.vm*"
            "*.nvram"
            "*.rcore"
            "*.swp"
            "*.swap"
            "lzo"
            "litmain.sh"
            "*.orig"
            ".histfile.*"
            ".xsession-errors*"
            "*.map"
            "*.so"
            "*.a"
            "*.db"
            "*.qrc"
            "*.ini"
            "*.init"
            "*.img"
            "*.vdi"
            "*.vbox*"
            "vbox.log"
            "*.qcow2"
            "*.vmdk"
            "*.vhd"
            "*.vhdx"
            "*.sql"
            "*.sql.gz"
            "*.ytdl"
            "*.tfstate*"
            "*.class"
            "*.pyc"
            "*.pyo"
            "*.elc"
            "*.qmlc"
            "*.jsc"
            "*.fastq"
            "*.fq"
            "*.gb"
            "*.fasta"
            "*.fna"
            "*.gbff"
            "*.faa"
            "po"
            "CVS"
            ".svn"
            ".git"
            "_darcs"
            ".bzr"
            ".hg"
            "CMakeFiles"
            "CMakeTmp"
            "CMakeTmpQmake"
            ".moc"
            ".obj"
            ".pch"
            ".uic"
            ".npm"
            ".yarn"
            ".yarn-cache"
            "__pycache__"
            "node_modules"
            "node_packages"
            "nbproject"
            ".terraform"
            ".venv"
            "venv"
            "core-dumps"
            "lost+found"
            ".snapshots"

            "_build"
            "deps"
            "target"
            "dist"
          ];
          "exclude filters version" = 9;
        };

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
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.switch-to-previous-desktop
      ];
    };

  # The games live on their own desktop, Meta+7.
  flake.modules.homeManager.gaming.programs.plasma.kwin.virtualDesktops.number = 7;
}
