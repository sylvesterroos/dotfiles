{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.determinate.nixosModules.default

    ./hardware-configuration.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  nix = {
    channel.enable = false;
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/46d67494-b781-464f-9584-723c39358dc7";
      fsType = "xfs";
      options = ["relatime" "inode64"];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
      options = ["noatime"];
      neededForBoot = true;
    };
  };

  networking.hostName = "raspberry-pi";

  users.users = {
    sylvester = {
      isNormalUser = true;
      description = "Sylvester Roos";
      shell = pkgs.fish;
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

  environment.systemPackages = with pkgs; [
    neovim
    nil
  ];

  documentation.man.generateCaches = false;

  ###
  # Services
  ###

  services.openssh.enable = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  ###
  # Programs
  ###

  programs.nix-ld = {
    enable = true;
  };

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--nogcroots --keep-since 14d";
    };
    flake = "/home/sylvester/.dotfiles/nix-systems";
  };

  system.stateVersion = "26.05";
}
