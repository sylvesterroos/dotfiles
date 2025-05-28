{ inputs, ... }:

{
  hardware.tuxedo-drivers.enable = true;

  hardware.tuxedo-control-center = {
    enable = false;
    package = inputs.tuxedo-nixos.packages.x86_64-linux.default;
  };
}
