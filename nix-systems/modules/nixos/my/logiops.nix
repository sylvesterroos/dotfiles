{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.logiops;
in {
  options.my.logiops = {
    enable =
      mkEnableOption "logiops"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    systemd.packages = [pkgs.logiops];
    systemd.services.logid.wantedBy = ["multi-user.target"];
  };
}
