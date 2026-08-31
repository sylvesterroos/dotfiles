{
  pkgs,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "keep";
  boot.loader.efi.canTouchEfiVariables = true;
  # 0 = menu hidden, boots silently; hold space/esc/arrows at power-on to enter it
  boot.loader.timeout = 0;

  # secure boot
  environment.systemPackages = with pkgs; [ sbctl ];
}
