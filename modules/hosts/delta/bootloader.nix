{ inputs, ... }:
{
  flake.modules.nixos.delta =
    { pkgs, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      # Secure Boot with our own keys. The first boot generates them and
      # reboots; systemd-boot then enrolls them while the firmware is in
      # setup mode. Microsoft's keys stay, so Windows and signed option ROMs
      # keep booting. Gigabyte firmware rejects enrollment with the firmware's
      # built-in keys (duplicate db entries end in a Secure Boot Violation).
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        autoGenerateKeys.enable = true;
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };
      };
      boot.loader.systemd-boot.consoleMode = "keep";
      boot.loader.efi.canTouchEfiVariables = true;
      # 0 = menu hidden, boots silently; hold space/esc/arrows at power-on to enter it
      boot.loader.timeout = 0;

      environment.systemPackages = [ pkgs.sbctl ];
    };
}
