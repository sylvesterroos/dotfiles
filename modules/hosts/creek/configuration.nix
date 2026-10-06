# Creek: Tuxedo Pulse 15 laptop.
{ config, ... }:
{
  configurations.nixos.creek = {
    nixpkgs = "tip";
    module = {
      imports = with config.flake.modules.nixos; [
        desktop
        hindsight
        creek
      ];
      home-manager.users.sylvester.imports = [ config.flake.modules.homeManager.creek ];
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

      services.postgresql = {
        package = pkgs.postgresql_18;
        # non-default port so we don't get in the way of development postgres instances
        settings.port = 5431;
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

      my.headscaled = {
        enable = true;
        httpProxy = {
          listen = "localhost:1055";
          domain = "tailnet.sylvesterroos.com";
        };
      };

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      system.stateVersion = "23.05";
    };
}
