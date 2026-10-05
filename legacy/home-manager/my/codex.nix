{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.codex;
in
{
  options.my.codex = {
    enable = mkEnableOption "codex" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
    };
  };
}
