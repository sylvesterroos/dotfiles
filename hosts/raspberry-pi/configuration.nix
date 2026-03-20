{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    outputs.nixosModules.my

    inputs.determinate.nixosModules.default
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.sops-nix.nixosModules.sops

    ./caddy.nix
    ./ddns-updater.nix
    ./dns.nix
    ./fail2ban.nix
    ./hardware-configuration.nix
    ./hermes-agent-deps.nix
    ./immich.nix
    ./immich-backup.nix
    ./jellyfin.nix
    ./postgresql.nix
    ./srv.nix
    ./syncthing.nix
    ./torrents.nix
    ./vaultwarden.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];

    config = {
      allowUnfree = true;
    };
  };

  nix = {
    channel.enable = false;
    settings.cores = 3;
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096;
    }
  ];

  networking.hostName = "raspberry-pi";

  users.users = {
    sylvester = {
      uid = 1000;
      initialPassword = "password";
      isNormalUser = true;
      description = "Sylvester Roos";
      shell = pkgs.bash;
      extraGroups = [
        "wheel"
        "networkmanager"
        "plugdev"
      ];
      createHome = true;
    };
  };
  programs.fish.enable = true;

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
    git
    neovim
    nil
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

  ###
  # Programs
  ###

  system.stateVersion = "26.05";
}
