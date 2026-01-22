{ inputs, ... }:

{
  hardware.tuxedo-drivers.enable = true;

  imports = [ inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2 ];
}
