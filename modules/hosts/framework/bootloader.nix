{ inputs, ... }:
{
  flake.modules.nixos.framework =
    { pkgs, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      # Secure Boot with our own keys. The first boot generates them and
      # reboots; systemd-boot then enrolls them while the firmware is in
      # setup mode. Framework's built-in keys stay so its firmware updates
      # keep installing.
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        autoGenerateKeys.enable = true;
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
          includeFirmwareBuiltinKeys = true;
        };
      };
      boot.loader.efi.canTouchEfiVariables = true;
      environment.systemPackages = [ pkgs.sbctl ];
    };
}
