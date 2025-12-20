{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.nixos-flatpak;
in {
  options.my.nixos-flatpak = {
    enable =
      mkEnableOption "NixOS Flatpak support"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
