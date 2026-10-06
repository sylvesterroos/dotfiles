# What every host shares: Determinate Nix, the flake's overlays, unfree
# packages, NetworkManager and the Amsterdam time zone.
{ config, inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.determinate.nixosModules.default ];

    nixpkgs = {
      overlays = with config.flake.overlays; [
        additions
        modifications
        pins
      ];
      config.allowUnfree = true;
    };

    nix.channel.enable = false;

    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Amsterdam";

    services.fstrim.enable = true;
  };
}
