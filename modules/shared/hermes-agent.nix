# The Hermes Agent user environment: what a user needs to run Hermes Agent.
# Single source of truth for the env facts. Both the NixOS-level module (hosts
# without home-manager, e.g. bachus) and the home-manager module (creek, delta)
# map these facts onto their own option sets, so a change here applies
# everywhere.
{
  lib,
  pkgs,
}:
{
  # agent-browser only exists in unstable. On a stable host (bachus) reach it
  # through the unstable overlay; on an unstable host (creek, delta) it's a
  # first-class package.
  packages = [
    (pkgs.agent-browser or pkgs.unstable.agent-browser)
  ];

  sessionVariables = {
    HERMES_TUI = "1";
    AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
  };
}
