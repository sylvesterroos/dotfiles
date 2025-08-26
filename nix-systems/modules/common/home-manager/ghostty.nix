{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    installBatSyntax = true;
    settings = {
      # theme = "light:catppuccin-latte,dark:catppuccin-macchiato";
      theme = "light:catppuccin-latte,dark:Ghostty Default StyleDark";
      # On Plasma we also want the nice GTK menu bar
      window-decoration = "client";
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
}
