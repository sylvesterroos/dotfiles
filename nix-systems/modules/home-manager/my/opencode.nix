{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.opencode;
in {
  options.my.opencode = {
    enable =
      mkEnableOption "opencode"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.opencode.enable = true;
  };
}
