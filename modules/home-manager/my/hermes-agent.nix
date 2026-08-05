{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.hermes-agent;
in
{
  options.my.hermes-agent = {
    enable = mkEnableOption "hermes agent" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      # Local headless browser backend for the browser tool. agent-browser
      # drives chromium via CDP — zero cloud-browser cost.
      pkgs.agent-browser
      pkgs.chromium
    ];

    home.sessionVariables = {
      # Launch the Ink TUI by default instead of the classic REPL.
      HERMES_TUI = "1";
      # Point agent-browser at the nixpkgs chromium instead of downloading
      # its own Playwright build.
      AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
    };

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
