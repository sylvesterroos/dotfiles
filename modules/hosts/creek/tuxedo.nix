{ inputs, ... }:
{
  flake.modules.nixos.creek = {
    hardware.tuxedo-drivers.enable = true;

    imports = [ inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2 ];
  };
}
