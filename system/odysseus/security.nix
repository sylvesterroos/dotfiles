{ pkgs, lib, ... }:

{
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
  };
}
