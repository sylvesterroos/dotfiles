{
  flake.modules.homeManager.creek =
    { pkgs, ... }:
    {
      # macos-like font rendering
      # https://blog.aktsbot.in/no-more-blurry-fonts.html
      systemd.user.sessionVariables.FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";

      programs.vscode = {
        enable = true;
        package = pkgs.vscode-fhs;
      };

      home.stateVersion = "23.05";
    };
}
