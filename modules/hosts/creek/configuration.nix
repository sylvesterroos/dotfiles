# Creek: Tuxedo Pulse 15 laptop.
{ config, ... }:
{
  configurations.nixos.creek = {
    nixpkgs = "tip";
    sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJwLILTn1Fcv2rWpEnPj2Zjzl1hbSb5xVHua5yWtrYV";
    module = {
      imports = with config.flake.modules.nixos; [
        desktop
        programming
        headscaled
        logiops
        creek
      ];
      home-manager.users.sylvester.imports = with config.flake.modules.homeManager; [
        linux-wallpaperengine
        creek
      ];
    };
  };

  flake.modules.nixos.creek =
    { lib, pkgs, ... }:
    {
      networking.hostName = "creek";

      boot.kernelPackages = pkgs.linuxPackages_zen;

      environment.variables = {
        EDITOR = lib.getExe pkgs.neovim;

        # https://consoledonottrack.com/
        DO_NOT_TRACK = 1;
      };

      programs.gnupg.agent.enable = true;

      services.fwupd.enable = true;

      boot.zswap = {
        enable = true;
        maxPoolPercent = 50; # 50% of 32GB
      };

      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 16 * 1024; # 16 GiB, backs the zswap pool
        }
      ];

      my.headscaled.network = config.headscaleNetwork;

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      system.stateVersion = "23.05";
    };
}
