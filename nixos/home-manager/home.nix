# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      # outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix.gc = outputs.gc-settings;

  home = {
    username = "sylvester";
    homeDirectory = "/home/sylvester";
  };

  # Add stuff for your user as you see fit:
  home.packages = with pkgs; [
    stow
    podman-compose
    pods
    xsel
    wl-clipboard
    ranger
    findutils
    fd
    neofetch
    onefetch
    nextcloud-client
    figlet # making large letters out of ordinary text
    mission-center
    livebook
    zed-editor
    devenv
    betterdiscordctl
    via
    gitleaks
    magit

    # extra gnome packages
    gnome-tweaks
    gnome.gnome-software
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.pano
    gnomeExtensions.quick-settings-tweaker
    gnomeExtensions.rounded-window-corners
    #gnomeExtensions.solaar-extension
  ];

  home.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    # fuck microsoft
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";

    # needed for vscodium
    VSCODE_GALLERY_SERVICE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery";
    VSCODE_GALLERY_ITEM_URL = "https://marketplace.visualstudio.com/items";
    VSCODE_GALLERY_CACHE_URL = "https://vscode.blob.core.windows.net/gallery/index";
    VSCODE_GALLERY_CONTROL_URL = "";
  };

  programs.home-manager.enable = true;

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
  };

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    extraPackages = with pkgs; [
      jq # %!jq
      cargo # dependencies built with rust
      gcc # telescope, luasnip
      go # golsp
      ripgrep # telescope
      fd # telescope
      fzf # telescope
      nodePackages_latest.nodejs # copilot
      markdownlint-cli # markdown
      typescript # tsserver
      nodePackages.typescript-language-server # tsserver
    ];
  };

  programs.git = {
    enable = true;
    diff-so-fancy.enable = true;
    userEmail = "sylvester@thejoyofcoding.nl";
    userName = "Sylvester Roos";
    extraConfig = {
      init.defaultBranch = "master";
      core = {
        editor = "flatpak run re.sonny.Commit";
        autocrlf = "input"; # convert CRLF to LF on commit
      };
    };
    signing = {
      key = null;
      signByDefault = true;
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza -alg --color=always --group-directories-first --header";

      cat = "bat -pp"; # no line numbers, no pager

      ssh-keygen-ed25519 = "ssh-keygen -t ed25519 -C (whoami)@(uname -n)";
    };
    interactiveShellInit = ''
      alias :q="exit"
    '';
    shellAbbrs = {
      rebuild-system = "sudo nixos-rebuild --flake path:$HOME/.dotfiles/nixos#odysseus";

      nsh = "nix-shell --run fish";
      # nshu = "nix-shell --run fish -I nixpkgs=channel:nixpkgs-unstable";

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

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
  };

  programs.starship.enable = true;
  programs.autojump.enable = true;
  programs.yt-dlp.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
