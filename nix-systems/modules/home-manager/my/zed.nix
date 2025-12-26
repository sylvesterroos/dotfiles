{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.my.zed-editor;
in {
  options.my.zed-editor = {
    enable =
      mkEnableOption "zed-editor"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.zed-editor.enable = true;

    home.sessionVariables = {
      VISUAL = lib.getExe pkgs.zed-editor;
      GIT_EDITOR = "${lib.getExe pkgs.zed-editor} --wait";
    };

    home.packages = with pkgs; [
      (pkgs.writeShellScriptBin "zed" ''
        exec ${lib.getExe pkgs.zed-editor} "$@"
      '')
    ];
  };
}
