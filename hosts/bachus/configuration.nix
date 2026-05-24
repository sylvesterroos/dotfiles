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

    ./caddy.nix
    ./open-webui.nix
    ./ddns-updater.nix
    ./disk-config.nix
    ./fail2ban.nix
    ./hardware-configuration.nix
    # ./immich-backup.nix
    ./immich.nix
    ./jellyfin.nix
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
    unstable.amp-cli
    unstable.devenv
    unstable.opencode
    yazi
  ];

  environment.variables = {
    EDITOR = lib.getExe pkgs.neovim;
  };

  environment.shellAliases = {
    hermes = "docker exec -it --user=hermes hermes-agent /opt/hermes/.venv/bin/hermes";
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
