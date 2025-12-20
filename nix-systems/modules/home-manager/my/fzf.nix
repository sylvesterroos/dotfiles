{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.my.fzf;
in {
  options.my.fzf = {
    enable =
      mkEnableOption "fzf"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
    };
  };
}
