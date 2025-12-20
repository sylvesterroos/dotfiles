{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.my.ghostty;
in {
  options.my.ghostty = {
    enable =
      mkEnableOption "ghostty"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package =
        if pkgs.stdenv.isLinux
        then pkgs.ghostty
        else pkgs.ghostty-bin;
      installBatSyntax = true;
      settings = {
        # theme = "light:catppuccin-latte,dark:catppuccin-macchiato";
        theme = "light:Catppuccin Latte,dark:Ghostty Default Style Dark";
        # On Plasma we also want the nice GTK menu bar
        window-decoration =
          if pkgs.stdenv.isLinux
          then "client"
          else "auto";
        keybind = [
          "shift+ctrl+r=reload_config"

          "ctrl+w>h=goto_split:left"
          "ctrl+w>j=goto_split:down"
          "ctrl+w>k=goto_split:up"
          "ctrl+w>l=goto_split:right"

          "shift+ctrl+h=new_split:left"
          "shift+ctrl+j=new_split:down"
          "shift+ctrl+k=new_split:up"
          "shift+ctrl+l=new_split:right"
        ];
      };
    };
  };
}
