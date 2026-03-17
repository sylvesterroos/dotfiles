{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.yazi;
in
{
  options.my.yazi = {
    enable = mkEnableOption "yazi" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
    }
    // optionalAttrs (config.home.stateVersion < "26.05") {
      shellWrapperName = "y";
    };
  };
}
