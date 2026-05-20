{
  pkgs,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # secure boot
  environment.systemPackages = with pkgs; [ sbctl ];
}
