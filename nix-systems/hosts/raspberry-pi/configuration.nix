{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    outputs.nixosModules.my

    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.determinate.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix
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
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  networking.hostName = "raspberry-pi";

  users.users = {
    sylvester = {
      initialPassword = "password";
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
    git
    neovim
    nil
  ];

  documentation.man.generateCaches = false;

  ###
  # My
  ###

  my = {
    audio.enable = false;
    avahi.enable = false;
    brave-browser.enable = false;
    nixos-flatpak.enable = false;
    keyboard.enable = false;
    logiops.enable = false;
    podman.enable = false;
    printing.enable = false;
    virtual-machines.enable = false;
  };

  ###
  # Services
  ###

  ###
  # Programs
  ###

  system.stateVersion = "26.05";
}
