# Delta: desktop on a Gigabyte B550 board with an AMD GPU.
{
  config,
  inputs,
  ...
}:
{
  configurations.nixos.delta = {
    nixpkgs = "tip";
    module = {
      imports = with config.flake.modules.nixos; [
        desktop
        gaming
        programming
        headscaled
        livebook
        logiops
        delta
      ];
      home-manager.users.sylvester.imports = with config.flake.modules.homeManager; [
        linux-wallpaperengine
        delta
      ];
    };
  };

  flake.modules.nixos.delta =
    { pkgs, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.gigabyte-b550 ];

      networking.hostName = "delta";

      boot.kernelPackages = pkgs.linuxPackages_xanmod;

      my.headscaled.network = config.headscaleNetwork;

      networking.networkmanager.ensureProfiles.profiles."Wired internet" = {
        connection = {
          id = "Wired internet";
          type = "802-3-ethernet";
          interface-name = "eno1";
          uuid = "567f035d-b139-4ba8-ab0e-0c08f5d6af10";
        };
        ethtool.eee-enabled = "off";
      };

      boot.zswap.enable = true;

      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 8 * 1024; # 8 GiB
        }
      ];

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      system.stateVersion = "25.05";
    };
}
