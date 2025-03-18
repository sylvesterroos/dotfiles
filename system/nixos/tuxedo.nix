{ inputs, ... }:

{
  hardware.tuxedo-control-center = {
    enable = true;
    package = inputs.tuxedo-nixos.packages.x86_64-linux.default;
  };

  hardware.tuxedo-rs = {
    enable = false;
    tailor-gui.enable = false;
  };
}
