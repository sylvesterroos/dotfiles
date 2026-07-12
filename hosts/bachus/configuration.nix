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
    inputs.open-design.nixosModules.default
    inputs.sops-nix.nixosModules.sops

    # ./immich-backup.nix
    ./caddy.nix
    ./ddns-updater.nix
    ./disk-config.nix
    ./fail2ban.nix
    ./hardware-configuration.nix
    ./home-assistant.nix
    ./immich.nix
    ./jellyfin.nix
    ./open-design.nix
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
    unstable.amp-cli
    unstable.codex
    unstable.devenv
    unstable.opencode
    yazi
  ];

  environment.variables = {
    EDITOR = lib.getExe pkgs.neovim;
  };

  environment.shellAliases = {
    hermes = "podman exec -it --user=hermes hermes-agent /opt/hermes/.venv/bin/hermes";
    hermes-mom = "podman exec -it --user=hermes hermes-agent-mom /opt/hermes/.venv/bin/hermes";
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
