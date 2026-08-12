{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.hermes-agent;
  hermesEnv = import ../../shared/hermes-agent.nix {
    inherit lib pkgs;
  };
in
{
  options.my.hermes-agent = {
    enable = mkEnableOption "hermes agent" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = hermesEnv.packages;

    home.sessionVariables = hermesEnv.sessionVariables;

    # Launcher entry for the hermes-desktop Electron app, installed via
    # `nix profile install github:NousResearch/hermes-agent#desktop`. The
    # icon lives inside that same profile, so the path tracks package
    # updates automatically. StartupWMClass matches the window class KWin
    # observes for the app (resourceClass: hermes).
    xdg.desktopEntries.hermes = {
      name = "Hermes";
      comment = "Native desktop shell for Hermes Agent";
      exec = "hermes-desktop";
      icon = "${config.home.homeDirectory}/.nix-profile/share/hermes-desktop/dist/nous-girl.jpg";
      terminal = false;
      categories = [
        "Development"
        "Utility"
      ];
      startupNotify = true;
      settings.StartupWMClass = "hermes";
    };
  };
}
