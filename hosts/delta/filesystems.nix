{ lib, ... }:
{
  # mkForce is needed to override the hardware-configuration value?
  fileSystems."/home/sylvester/Games" = lib.mkForce {
    device = "/dev/disk/by-label/Linux_Games";
    fsType = "xfs";
    options = [
      "nofail"
      "nodiratime"
    ];
  };
}
