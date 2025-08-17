{
  pkgs,
  config,
  ...
}: {
  boot.loader.systemd-boot.enable = !config.boot.lanzaboote.enable;
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "nodev";
  #boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # secure boot
  environment.systemPackages = with pkgs; [sbctl];

  # Lanzaboote currently replaces the systemd-boot module.
  boot.lanzaboote = {
    enable = false;
    pkiBundle = "/var/lib/sbctl";
  };
}
