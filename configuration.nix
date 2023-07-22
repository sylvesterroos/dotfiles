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
    "openssl-1.1.1u"
    "nodejs-14.21.3"
    "electron-13.6.9"
  ];

  nixpkgs.overlays = [(import (builtins.fetchGit {                                                            
                      url = "https://github.com/nix-community/nix-vscode-extensions";
                      ref = "refs/heads/master";
                    })).overlays.default];

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
  home-manager.users.sylvester = { pkgs, ... }: {
    home.stateVersion = "23.05";
    home.packages = with pkgs; [
      fish
      flatpak
      firefox
      thunderbird
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
    ];

    # project management
    # programs.direnv.enable = true;
    # programs.direnv.nix-direnv.enable = true;

    programs.fish.enable = true;
    programs.fish.shellAliases = {
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
      yt-dl = "youtube-dl";
      yta-aac = "youtube-dl --add-metadata --extract-audio --audio-format aac ";
      yta-best = "youtube-dl --add-metadata --extract-audio --audio-format best ";
      yta-flac = "youtube-dl --add-metadata --extract-audio --audio-format flac ";
      yta-m4a = "youtube-dl --add-metadata --extract-audio --audio-format m4a ";
      yta-mp3 = "youtube-dl --add-metadata --extract-audio --audio-format mp3 ";
      yta-opus = "youtube-dl --add-metadata --extract-audio --audio-format opus ";
      yta-vorbis = "youtube-dl --add-metadata --extract-audio --audio-format vorbis ";
      yta-wav = "youtube-dl --add-metadata --extract-audio --audio-format wav ";
      ytv-best = "youtube-dl --add-metadata -f bestvideo+bestaudio ";

      # the terminal rickroll
      rr = "curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash";
    };
    programs.fish.interactiveShellInit = ''
      # asdf
      #source $HOME/.asdf/asdf.fish
    '';

    programs.starship = {
      enable = true;

      settings = {
        aws = {
          format = "\\[[$symbol($profile)(\\($region\\))(\\[$duration\\])]($style)\\]";
        };
        bun = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        c = {
          format = "\\[[$symbol($version(-$name))]($style)\\]";
        };
        cmake = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        cmd_duration = {
          disabled = true;
          format = "\\[[⏱ $duration]($style)\\]";
        };
        cobol = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        conda = {
          format = "\\[[$symbol$environment]($style)\\]";
        };
        crystal = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        daml = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        dart = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        deno = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        docker_context = {
          format = "\\[[$symbol$context]($style)\\]";
        };
        dotnet = {
          format = "\\[[$symbol($version)(🎯 $tfm)]($style)\\]";
        };
        elixir = {
          format = "\\[[$symbol($version \\(OTP $otp_version\\))]($style)\\]";
        };
        elm = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        erlang = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        fennel = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        fossil_branch = {
          format = "\\[[$symbol$branch]($style)\\]";
        };
        gcloud = {
          format = "\\[[$symbol$account(@$domain)(\\($region\\))]($style)\\]";
        };
        git_branch = {
          format = "\\[[$symbol$branch]($style)\\]";
        };
        git_status = {
          format = "([\\[$all_status$ahead_behind\\]]($style))";
        };
        golang = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        gradle = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        guix_shell = {
          format = "\\[[$symbol]($style)\\]";
        };
        haskell = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        haxe = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        helm = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        hg_branch = {
          format = "\\[[$symbol$branch]($style)\\]";
        };
        java = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        julia = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        kotlin = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        kubernetes = {
          format = "\\[[$symbol$context( \\($namespace\\))]($style)\\]";
        };
        lua = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        memory_usage = {
          format = "\\[$symbol[$ram( | $swap)]($style)\\]";
        };
        meson = {
          format = "\\[[$symbol$project]($style)\\]";
        };
        nim = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        nix_shell = {
          format = "\\[[$symbol$state( \\($name\\))]($style)\\]";
        };
        nodejs = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        ocaml = {
          format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]";
        };
        opa = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        openstack = {
          format = "\\[[$symbol$cloud(\\($project\\))]($style)\\]";
        };
        os = {
          format = "\\[[$symbol]($style)\\]";
        };
        package = {
          format = "\\[[$symbol$version]($style)\\]";
        };
        perl = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        php = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        pijul_channel = {
          format = "\\[[$symbol$channel]($style)\\]";
        };
        pulumi = {
          format = "\\[[$symbol$stack]($style)\\]";
        };
        purescript = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        python = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        raku = {
          format = "\\[[$symbol($version-$vm_version)]($style)\\]";
        };
        red = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        ruby = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        rust = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        scala = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        spack = {
          format = "\\[[$symbol$environment]($style)\\]";
        };
        sudo = {
          format = "\\[[as $symbol]($style)\\]";
        };
        swift = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        terraform = {
          format = "\\[[$symbol$workspace]($style)\\]";
        };
        time = {
          format = "\\[[$time]($style)\\]";
        };
        username = {
          format = "\\[[$user]($style)\\]";
        };
        vagrant = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        vlang = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        zig = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
        solidity = {
          format = "\\[[$symbol($version)]($style)\\]";
        };
      };
    };

    programs.git = {
      enable = true;
      userName = "Sylvester Roos";
      userEmail = "pistrie@duck.com";
    };
  };

  # enable fish shell so user can use it
  programs.fish.enable = true;

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
	vspacecode.vspacecode

	# dependencies
	vspacecode.whichkey
	bodil.file-browser
	jacobdufault.fuzzy-search
	kahole.magit
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
}
