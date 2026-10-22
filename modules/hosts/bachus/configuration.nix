# Bachus: home server. Serves the public sites, the tailnet services and the
# attic cache; tracks the latest stable nixpkgs.
{
  config,
  inputs,
  lib,
  ...
}:
let
  mv = config.multiverse;
in
{
  configurations.nixos.bachus = {
    nixpkgs = lib.last mv.releases;
    module.imports = with config.flake.modules.nixos; [
      without-home-manager
      attic-server
      headscaled
      hermes-gateway
      hindsight
      bachus
    ];
  };

  flake.modules.nixos.bachus =
    { lib, pkgs, ... }:
    {
      imports = [
        inputs.copyparty.nixosModules.default
        inputs.disko.nixosModules.default
      ];

      networking.hostName = "bachus";

      nix.settings.cores = 6;

      boot.loader.systemd-boot = {
        enable = true;
        consoleMode = "keep";
        memtest86.enable = true;
      };
      boot.loader.efi.canTouchEfiVariables = true;
      # 0 = menu hidden, boots silently; hold space/esc/arrows at power-on to enter it
      boot.loader.timeout = 0;

      environment.systemPackages = with pkgs; [
        ghostty.terminfo
        git
        gitu
        neovim
        nil
        stow
        yazi
        mv.tip.devenv
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
      ];

      environment.variables.EDITOR = lib.getExe pkgs.neovim;

      programs.nh.flake = "/srv/nixos";

      my.postgresql.dbaUsers = [ { userName = "sylvester"; } ];

      zramSwap = {
        enable = true;
        memoryPercent = 25;
        algorithm = "zstd";
      };

      system.stateVersion = "25.11";
    };
}
