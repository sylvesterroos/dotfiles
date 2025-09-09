{pkgs, ...}: {
  # Required to configure ZSA keyboards using Oryx
  hardware.keyboard.zsa.enable = true;

  # required to configure QMK keyboard as a non-root user
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = with pkgs; [keymapp];
}
