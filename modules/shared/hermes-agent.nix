# The Hermes Agent user environment: what a user needs to run Hermes Agent.
# Single source of truth for the env facts. Both the NixOS-level module (hosts
# without home-manager, e.g. bachus) and the home-manager module (creek, delta)
# map these facts onto their own option sets, so a change here applies
# everywhere.
{
  lib,
  pkgs,
}:
let
  # Removes first: nix profile add refuses to replace a same-named element (file conflict),
  # so re-running would otherwise pile up `-1`-suffixed duplicates.
  hermesAgentUpdate = pkgs.writers.writeNuBin "hermes-agent-update" ''
    let tag = (http get https://api.github.com/repos/NousResearch/hermes-agent/releases/latest | get tag_name)
    print $"Updating hermes-agent to ($tag)"
    try { nix profile remove hermes-agent }
    try { nix profile remove desktop }
    nix profile add $"github:NousResearch/hermes-agent/($tag)#packages.x86_64-linux.default"
    nix profile add $"github:NousResearch/hermes-agent/($tag)#packages.x86_64-linux.desktop"
  '';
in
{
  # agent-browser only exists in unstable. On a stable host (bachus) reach it
  # through the unstable overlay; on an unstable host (creek, delta) it's a
  # first-class package.
  packages = [
    (pkgs.agent-browser or pkgs.unstable.agent-browser)
    hermesAgentUpdate
  ];

  sessionVariables = {
    HERMES_TUI = "1";
    AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
  };
}
