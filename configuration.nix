# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  tuxedo = import (builtins.fetchTarball "https://github.com/blitz/tuxedo-nixos/archive/master.tar.gz");
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      tuxedo.module
    ];
  hardware.tuxedo-control-center.enable = true;
  # required for tuxedo-control-center
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1v"
    "nodejs-14.21.3"
    "electron-13.6.9"
  ];

  nixpkgs.overlays = [
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/nix-vscode-extensions";
      ref = "refs/heads/master";
    })).overlays.default
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # direnv: protect nix-shell from garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sylvester = {
    isNormalUser = true;
    description = "Sylvester Roos";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  # enable fish shell so user can use it
  programs.fish.enable = true;

  # enable dconf so home-manager can use it
  programs.dconf.enable = true;

  home-manager.users.sylvester = { pkgs, lib, ... }: {
    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      fish
      flatpak
      brave
      firefox
      thunderbird
      celluloid
      vlc
      starship
      podman-compose
      pods
      element-desktop
      xsel
      wl-clipboard
      ranger
      findutils
      fd
      tealdeer
      logseq
      neofetch
      nextcloud-client

      # extra gnome packages
      gnome.gnome-tweaks
      gnome.gnome-software
      gnomeExtensions.gsconnect
      gnomeExtensions.appindicator
      gnomeExtensions.pano
      gnomeExtensions.dash-to-dock
      gnomeExtensions.rounded-window-corners
      gnomeExtensions.vitals
      gnomeExtensions.quick-settings-tweaker
      # gnomeExtensions.solaar-extension
    ];

    dconf.settings = {
      "org/gnome/desktop/search-providers/disabled" = {
        disabled = [ "org.gnome.Epiphany.desktop" "org.gnome.Photos.desktop" ];
        sort-order = [ "org.gnome.Documents.desktop" "org.gnome.Nautilus.desktop" "org.gnome.Contacts.desktop" ];
      };

      "org/gnome/desktop/interface" = {
        enable-hot-corners = false;
        show-battery-percentage = true;
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

      # gnome tweaks
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close,minimize:appmenu";
        focus-mode = "sloppy";
        resize-with-right-button = true;
      };

    };

    programs.git = {
      enable = true;
      diff-so-fancy.enable = true;
      userEmail = "sylvester@thejoyofcoding.nl";
      userName = "hyperspace";
    };
    programs.fish = {
      enable = true;
      shellAliases = {
        # changing "ls" to "exa"
        ls = "exa -alg --color=always --group-directories-first --header"; # my preferred listing
        la = "exa -a --color=always --group-directories-first --header"; # all files and dirs
        ll = "exa -l --color=always --group-directories-first --header"; # long format
        lt = "exa -aT --color=always --group-directories-first --header"; # tree listing

        # dotfiles stuff
        dot = "/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
        suf = "dot config --local status.showUntrackedFiles no";

        # generating a new ssh key
        ssh-keygen-ed25519 = "ssh-keygen -t ed25519 -C (whoami)@(uname -n)";

        # youtube-dl
        yta-best = "yt-dlp --add-metadata --extract-audio --audio-format best ";
        ytv-best = "yt-dlp --add-metadata -f bestvideo+bestaudio ";

        # the terminal rickroll
        rr = "curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash";
      };
      interactiveShellInit = ''
        # asdf
        #source $HOME/.asdf/asdf.fish
      '';
    };

    programs.starship = {
      enable = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    wget
    exa
    ripgrep
    unzip
    logiops
    btop
    nil # dependency for nix-ide
    nixpkgs-fmt # dependency for nix-ide
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with (pkgs.forVSCodeVersion "1.78.2").vscode-marketplace; [
        zokugun.sync-settings
        vscodevim.vim
        alefragnani.project-manager
        arrterian.nix-env-selector
        gruntfuggly.todo-tree
        jakebecker.elixir-ls
        jdinhlife.gruvbox
        jnoortheen.nix-ide
        phoenixframework.phoenix
        redhat.vscode-yaml
        tenninebt.vscode-koverage
        # ryanluker.vscode-coverage-gutters # dependency ms-vscode.live-server not available for 1.78.2
        vspacecode.vspacecode
        mtxr.sqltools
        phind.phind
        mhutchie.git-graph
        github.copilot

        # dependencies
        zokugun.cron-tasks
        vspacecode.whichkey
        bodil.file-browser
        jacobdufault.fuzzy-search
        kahole.magit
        mtxr.sqltools-driver-pg
        # ms-vscode.live-server
      ];
    })
  ];

  # Set variables for the global environment
  environment.variables = {
    # fuck microsoft
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";

    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.flatpak.enable = true;
  services.locate.enable = true;
  systemd.packages = [ pkgs.logiops ];
  systemd.services.logid.wantedBy = [ "multi-user.target" ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  system.autoUpgrade.enable = true;

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
