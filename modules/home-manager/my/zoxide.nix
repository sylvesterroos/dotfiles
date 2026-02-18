{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.zoxide;
in
{
  options.my.zoxide = {
    enable = mkEnableOption "zoxide" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
    };
  };
}
