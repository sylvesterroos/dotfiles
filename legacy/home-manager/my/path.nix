{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.path;
in
{
  options.my.path = {
    enable = mkEnableOption "extra user PATH entries" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.sessionPath = [ "$HOME/.local/bin" ];
  };
}
