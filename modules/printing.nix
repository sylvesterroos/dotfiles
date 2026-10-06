{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      services.printing = {
        enable = true;
        drivers = with pkgs; [ cups-brother-mfcl2800dw ];
      };
    };
}
