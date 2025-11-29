{pkgs, ...}: {
  programs.zed-editor.enable = true;

  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "zed" ''
      exec zeditor "$@"
    '')
  ];
}
