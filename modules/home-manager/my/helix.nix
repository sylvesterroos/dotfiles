{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.helix-editor;
in
{
  options.my.helix-editor = {
    enable = mkEnableOption "helix-editor" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;
    };
  };
}
