{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.printing;
in {
  options.my.printing = {
    enable =
      mkEnableOption "printing"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = with pkgs; [cups-brother-mfcl2800dw];
    };
  };
}
