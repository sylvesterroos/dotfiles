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

    inputs.copyparty.nixosModules.default
    inputs.determinate.nixosModules.default
    inputs.disko.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # ./immich-backup.nix
    ./caddy.nix
    ./copyparty.nix
    ./ddns-updater.nix
    ./disk-config.nix
    ./fail2ban.nix
    ./hardware-configuration.nix
    ./home-assistant.nix
    ./immich.nix
    ./jellyfin.nix
    ./open-webui.nix
    ./plausible.nix
    ./postgresql.nix
    ./srv.nix
    ./syncthing.nix
    ./torrents.nix
    ./users.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages-baseline
    ];

    config = {
      allowUnfree = true;
    };
  };

  nix = {
    channel.enable = false;
    settings = {
      cores = 6;
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

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    git
    gitu
    neovim
    nil
    stow
    unstable.codex
    unstable.devenv
    unstable.opencode
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
    hermes-agent.enable = true;
    keyboard.enable = false;
    logiops.enable = false;
    nh.flake = "/srv/nixos";
    nixos-flatpak.enable = false;
    path.enable = true;
    podman.enable = true;
    printing.enable = false;
    virtual-machines.enable = false;

    security.openTCPPorts = [
      9119 # Hermes Agent web dashboard
    ];
  };

  my.postgresql.dbaUsers = [
    { userName = "sylvester"; }
  ];

  ###
  # Services
  ###

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
  };

  services.fstrim.enable = true;

  ###
  # Programs
  ###

  system.stateVersion = "25.11";
}
