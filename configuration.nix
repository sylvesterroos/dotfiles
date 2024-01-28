# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  #tuxedo = import (builtins.fetchTarball "https://github.com/blitz/tuxedo-nixos/archive/master.tar.gz");
  # to install packages from nixpkgs-unstable, for example unstable.livebook
  unstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
    #tuxedo.module
  ];
  #hardware.tuxedo-control-center.enable = true;
  hardware.tuxedo-rs = {
    enable = false;
    tailor-gui.enable = false;
  };
  # required to configure QMK keyboard as a non-root user
  hardware.keyboard.qmk.enable = true;
  nixpkgs.config.permittedInsecurePackages = [
    # required for tuxedo-control-center
    "openssl-1.1.1w"
    "nodejs-14.21.3"
    "electron-13.6.9"
    "electron-25.9.0" # logseq
  ];

  nixpkgs.overlays = [
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/nix-vscode-extensions";
      ref = "refs/heads/master";
    })).overlays.default
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null; };

  networking.hostName = "odysseus"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # enable fish shell so user can use it
  programs.fish.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sylvester = {
    isNormalUser = true;
    description = "Sylvester Roos";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "adbusers" "plugdev" ];
    shell = pkgs.fish;
  };

  # gsconnect
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users.sylvester = { pkgs, lib, ... }: {
    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      fish
      brave
      celluloid
      vlc
      podman-compose
      pods
      xsel
      wl-clipboard
      ranger
      findutils
      fd
      logseq
      neofetch
      onefetch
      ## TODO enable this using home-manager -> services.nextcloud...
      nextcloud-client
      mullvad-vpn
      jrnl
      figlet # making large letters out of ordinary text
      xwaylandvideobridge
      unstable.morewaita-icon-theme
      ### emacs stuff ###
      # vterm
      gnumake
      cmake
      # go
      go
      gopls
      gomodifytags
      gotests
      gore
      gotools
      # markdown
      python311Packages.grip
      discount
      # nix
      nil
      nixpkgs-fmt
      nixfmt
      # sh
      shfmt
      shellcheck
      # json
      nodePackages.vscode-json-languageserver
      # copilot
      nodePackages_latest.nodejs

      # extra gnome packages
      gnome.gnome-tweaks
      gnome.gnome-software
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
      gnomeExtensions.gtk4-desktop-icons-ng-ding
      gnomeExtensions.pano
      gnomeExtensions.quick-settings-tweaker
      gnomeExtensions.rounded-window-corners
      #gnomeExtensions.solaar-extension
      gnomeExtensions.vitals
    ];

    home.sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      # fuck microsoft
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";

      # needed for vscodium
      VSCODE_GALLERY_SERVICE_URL =
        "https://marketplace.visualstudio.com/_apis/public/gallery";
      VSCODE_GALLERY_ITEM_URL = "https://marketplace.visualstudio.com/items";
      VSCODE_GALLERY_CACHE_URL =
        "https://vscode.blob.core.windows.net/gallery/index";
      VSCODE_GALLERY_CONTROL_URL = "";
    };

    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
    };

    programs.neovim = { enable = true; };

    dconf.settings = {
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

      "org/gnome/system/location" = { enabled = true; };

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

      "org/gnome/desktop/wm/keybindings" = { close = [ "<Shift><Super>q" ]; };

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
    };

    programs.git = {
      enable = true;
      diff-so-fancy.enable = true;
      userEmail = "sylvester@thejoyofcoding.nl";
      userName = "Sylvester Roos";
      extraConfig = {
        init.defaultBranch = "master";
        core.editor = "flatpak run re.sonny.Commit";
      };
      signing = {
        key = null;
        signByDefault = true;
      };
    };

    programs.fish = {
      enable = true;
      shellAliases = {
        ls =
          "eza -alg --color=always --group-directories-first --header"; # my preferred listing
        la =
          "eza -a --color=always --group-directories-first --header"; # all files and dirs
        ll =
          "eza -l --color=always --group-directories-first --header"; # long format
        lt =
          "eza -aT --color=always --group-directories-first --header"; # tree listing

        cat = "bat -pp"; # no line numbers, no pager

        # dotfiles stuff
        dot = "/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
        suf = "dot config --local status.showUntrackedFiles no";

        ssh-keygen-ed25519 = "ssh-keygen -t ed25519 -C (whoami)@(uname -n)";
      };
      interactiveShellInit = ''
        #rtx activate fish | source
      '';
      shellAbbrs = {
        nsh = "nix-shell --run fish";
        nshu = "nix-shell --run fish -I nixpkgs=channel:nixpkgs-unstable";

        yta-best = "yt-dlp --add-metadata --extract-audio --audio-format best";
        ytv-best = "yt-dlp --add-metadata -f bestvideo+bestaudio";
      };
    };

    programs.tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.starship.enable = true;
    programs.autojump.enable = true;
    programs.yt-dlp.enable = true;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    noto-fonts
  ];

  # fixes flatpak packages with incorrect/incomplete fonts and cursor
  system.fsPackages = [ pkgs.bindfs ];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = [ "ro" "resolve-symlinks" "x-gvfs-hide" ];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.packages;
      pathsToLink = [ "/share/fonts" ];
    };
  in {
    # Create an FHS mount to support flatpak host icons/fonts
    "/usr/share/icons" = mkRoSymBind (config.system.path + "/share/icons");
    "/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # remove some default packages
  environment.gnome.excludePackages = with pkgs.gnome; [
    geary
    gnome-music
    gnome-weather
    totem
  ];
  services.xserver.excludePackages = [ pkgs.xterm ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    wget
    eza
    ripgrep
    unzip
    logiops
    #solaar
    btop
    bat
    ### virtualization ###
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    gnome.adwaita-icon-theme
    ### vscode ###
    (unstable.vscode-with-extensions.override {
      vscode = unstable.vscodium;
      vscodeExtensions = with (pkgs.forVSCodeVersion
        unstable.vscodium.version).vscode-marketplace; [
          zokugun.sync-settings
          vscodevim.vim
          asvetliakov.vscode-neovim
          vspacecode.vspacecode
          alefragnani.project-manager
          mkhl.direnv
          arrterian.nix-env-selector
          gruntfuggly.todo-tree
          jakebecker.elixir-ls
          elixir-tools.elixir-tools
          lexical-lsp.lexical
          jdinhlife.gruvbox
          phoenixframework.phoenix
          redhat.vscode-yaml
          tenninebt.vscode-koverage
          ryanluker.vscode-coverage-gutters
          mtxr.sqltools
          phind.phind
          mhutchie.git-graph
          tldraw-org.tldraw-vscode
          # github.copilot # doesn't work with vscodium
          #bruno-api-client.bruno

          # dependencies
          zokugun.cron-tasks
          vspacecode.whichkey
          bodil.file-browser
          jacobdufault.fuzzy-search
          kahole.magit
          mtxr.sqltools-driver-pg
          ms-vscode.live-server
        ];
    })
  ];

  # workaround for nautilus gstreamer plugin not working https://github.com/NixOS/nixpkgs/issues/195936#issuecomment-1278954466
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-plugins-ugly
      pkgs.gst_all_1.gst-libav
    ];

  # Set variables for the global environment
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Run unpatched dynamic binaries on NixOS
  # https://github.com/Mic92/nix-ld#usage
  programs.nix-ld.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # android-tools
  programs.adb.enable = true;

  # List services that you want to enable:
  services.flatpak.enable = true;
  services.locate.enable = true;
  services.mullvad-vpn.enable = true;
  systemd.packages = [ pkgs.logiops ];
  systemd.services.logid.wantedBy = [ "multi-user.target" ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.spice-vdagentd.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;

    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings = { dns_enabled = true; };
    };
  };

  # enable fwupd
  services.fwupd.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  system.autoUpgrade.enable = true;
  system.autoUpgrade.flags = [ "--upgrade-all" ];

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
