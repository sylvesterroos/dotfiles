{
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    outputs.nixosModules.my

    inputs.determinate.nixosModules.default
    inputs.disko.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # ./caddy.nix
    ./camofox.nix
    # ./ddns-updater.nix
    ./disk-config.nix
    ./fail2ban.nix
    ./hardware-configuration.nix
    ./hermes-agent.nix
    # ./immich-backup.nix
    # ./immich.nix
    # ./jellyfin.nix
    ./postgresql.nix
    ./srv.nix
    # ./syncthing.nix
    # ./torrents.nix
    ./users.nix
    # ./vaultwarden.nix
  ];

  services.postgresql.enable = true;

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  nix = {
    channel.enable = false;
    settings = {
      cores = 6;
      trusted-public-keys = [
        "delta:MfokDZYzRFSHuj8dIQuPVw5GoeFKUvOqJAVjJnxJ2RE="
      ];
    };
  };

  # Bootloader.
  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "bachus";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Amsterdam";

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

  # Prevents compilation of glibc-locales-aarch64-linux on remote (emulated?) builders
  i18n.supportedLocales = [ "all" ];

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    git
    gitu
    neovim
    nil
    unstable.opencode
    unstable.amp-cli
    yazi
  ];

  environment.variables = {
    EDITOR = lib.getExe pkgs.neovim;
  };

  ###
  # My
  ###

  my = {
    appimage.enable = false;
    audio.enable = false;
    avahi.enable = false;
    brave-browser.enable = false;
    keyboard.enable = false;
    logiops.enable = false;
    nh.flake = "/etc/nixos";
    nixos-flatpak.enable = false;
    podman.enable = true;
    printing.enable = false;
    virtual-machines.enable = false;
  };

  my.postgresql.dbaUsers = [
    { userName = "sylvester"; }
  ];

  ###
  # Services
  ###

  services.fstrim.enable = true;

  ###
  # Programs
  ###

  system.stateVersion = "25.11";
}
