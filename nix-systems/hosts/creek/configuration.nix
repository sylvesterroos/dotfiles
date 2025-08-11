# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    ./audio.nix
    ./avahi.nix
    ./bootloader.nix
    ./firewall.nix
    ./flatpak.nix
    ./gnome.nix
    ./livebook.nix
    # ./logiops.nix
    (import ./nh.nix {flakeDir = "/home/sylvester/.dotfiles/nix-systems";})
    ./nix-ld.nix
    ./packages.nix
    ./podman.nix
    ./power.nix
    ./printing.nix
    ./qmk.nix
    ./security.nix
    ./ssh.nix
    ./tailscale.nix
    ./tuxedo.nix
    ./users.nix
    ./virtual-machines.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      # outputs.overlays.unstable-packages
      outputs.overlays.stable-packages

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
    # Opinionated: disable channels
    channel.enable = false;

    settings.trusted-users = ["sylvester"];
  };

  networking.hostName = "creek";

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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.zed-mono
    noto-fonts

    libre-baskerville # times new roman alternative
  ];

  # Set variables for the global environment
  environment.variables = {
    EDITOR = lib.getExe pkgs.helix;
    VISUAL = lib.getExe pkgs.helix;

    # https://consoledonottrack.com/
    DO_NOT_TRACK = 1;
  };

  programs.gnupg.agent = {
    enable = true;
  };

  # android-tools
  programs.adb.enable = true;

  services.fwupd.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
