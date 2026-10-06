{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ghostty else pkgs.ghostty-bin;
        installBatSyntax = true;
        settings = {
          theme = "light:GitHub Light Colorblind,dark:GitHub Dark Colorblind";
          # On Plasma we also want the nice GTK menu bar
          window-decoration = if pkgs.stdenv.hostPlatform.isLinux then "client" else "auto";
          maximize = true;
          notify-on-command-finish = "unfocused";
          notify-on-command-finish-action = "no-bell,notify";
          font-feature = [ "-calt" ];
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
