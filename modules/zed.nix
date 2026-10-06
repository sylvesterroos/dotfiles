{
  flake.modules.homeManager.desktop =
    { pkgs, lib, ... }:
    {
      programs.zed-editor.enable = true;

      home.sessionVariables = {
        VISUAL = lib.getExe pkgs.zed-editor;
        GIT_EDITOR = "${lib.getExe pkgs.zed-editor} --wait";
      };

      home.packages = [
        pkgs.bubblewrap
        (pkgs.writeShellScriptBin "zed" ''
          exec ${lib.getExe pkgs.zed-editor} "$@"
        '')
      ];
    };
}
