{
  inputs,
  outputs,
  lib,
  mv,
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
    ./attic.nix
    ./caddy.nix
    ./copyparty.nix
    ./ddns-updater.nix
    ./disk-config.nix
    ./fail2ban.nix
    ./hardware-configuration.nix
    ./headscale.nix
    ./home-assistant.nix
    ./immich.nix
    ./jellyfin.nix
    ./open-webui.nix
    ./plausible.nix
    ./postgresql.nix
    ./srv.nix
    ./syncthing.nix
    ./tailnet-services.nix
    ./torrents.nix
    ./qui.nix
    ./users.nix
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
    settings = {
      cores = 6;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot = {
    enable = true;
    consoleMode = "keep";
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  # 0 = menu hidden, boots silently; hold space/esc/arrows at power-on to enter it
  boot.loader.timeout = 0;

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
    yazi
    mv.tip.codex
    mv.tip.devenv
    mv.tip.opencode
  ];

  environment.variables = {
    EDITOR = lib.getExe pkgs.neovim;
  };

  ###
  # My
  ###

  my = {
    agents.enable = true;
    appimage.enable = false;
    audio.enable = false;
    avahi.enable = false;
    brave-browser.enable = false;
    hermes-agent.enable = true;
    keyboard.enable = false;
    logiops.enable = false;
    nh.flake = "/srv/nixos";
    nixos-flatpak.enable = false;
    non-nix-apps.enable = false;
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
