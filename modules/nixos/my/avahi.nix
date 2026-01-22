{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.avahi;
in
{
  options.my.avahi = {
    enable = mkEnableOption "avahi" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
