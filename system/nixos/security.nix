{ pkgs, lib, ... }:

{
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
  };

  environment.systemPackages = lib.mkMerge [
    [ (lib.hiPrio pkgs.uutils-coreutils-noprefix) ]
  ];
}
