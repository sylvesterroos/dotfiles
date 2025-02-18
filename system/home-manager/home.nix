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
    ./dconf.nix
    ./fish.nix
    ./git.nix
    ./lf.nix
    ./neovim.nix
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

  nix = {
    settings = {
      # avoid rebuilding gitu
      extra-substituters = [ "https://gitu.cachix.org" ];
      extra-trusted-public-keys = [ "gitu.cachix.org-1:iUIaNys1l3W1LF/M8OXzaTl7N/OinGOlzdUJUSc+5eY=" ];
    };
  };

  nix.gc = outputs.gc-settings;

  home = {
    username = "sylvester";
    homeDirectory = "/home/sylvester";
  };

  # Add stuff for your user as you see fit:
  home.packages = (import ./packages.nix { inherit pkgs; });

  home.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    # fuck microsoft
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  };
  systemd.user.sessionVariables = {
    # macos-like font rendering
    # https://blog.aktsbot.in/no-more-blurry-fonts.html
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  programs.home-manager.enable = true;

  # services.kdeconnect = {
  #   enable = true;
  #   package = pkgs.gnomeExtensions.gsconnect;
  # };

  programs.command-not-found.enable = false;
  programs.nix-index.enable = true;

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-git;
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    mise.enable = true;
  };

  programs.gh = {
    enable = true;
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
  };

  # allow for more granular control over elixir versions
  programs.mise = {
    enable = true;
  };

  programs.starship.enable = true;
  programs.autojump.enable = true;
  programs.yt-dlp.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.05";
}
