# The Hermes Agent user environment: what a user needs to run Hermes Agent.
# Single source of truth for the env facts. Both the NixOS-level module (hosts
# without home-manager, e.g. bachus) and the home-manager module (creek, delta)
# map these facts onto their own option sets, so a change here applies
# everywhere.
{
  lib,
  mv,
  pkgs,
  cuaDriver,
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
  packages = [
    mv.tip.agent-browser
    mv.tip.claude-code # Anthropic authentication
  ]
  ++ lib.optionals (cuaDriver != null) [
    cuaDriver
    pkgs.imagemagick
    pkgs.at-spi2-core
  ]
  ++ [
    hermesAgentUpdate
  ];

  sessionVariables = {
    HERMES_TUI = "1";
    AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
  };
}
