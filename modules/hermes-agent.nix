# What a user needs to run Hermes Agent.
{ inputs, mv, ... }:
let
  env =
    { lib, pkgs }:
    {
      packages = [
        mv.tip.agent-browser
        mv.tip.claude-code # Anthropic authentication
        inputs.cua.packages.${pkgs.stdenv.hostPlatform.system}.cua-driver
        pkgs.imagemagick
        pkgs.at-spi2-core
        # nix profile add refuses to replace a same-named element, so remove
        # first; re-running would otherwise pile up `-1`-suffixed duplicates.
        (pkgs.writers.writeNuBin "hermes-agent-update" ''
          let tag = (http get https://api.github.com/repos/NousResearch/hermes-agent/releases/latest | get tag_name)
          print $"Updating hermes-agent to ($tag)"
          try { nix profile remove hermes-agent }
          try { nix profile remove desktop }
          nix profile add $"github:NousResearch/hermes-agent/($tag)#packages.x86_64-linux.default"
          nix profile add $"github:NousResearch/hermes-agent/($tag)#packages.x86_64-linux.desktop"
        '')
      ];

      sessionVariables = {
        HERMES_TUI = "1";
        AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
      };
    };
in
{
  flake.modules.homeManager.base =
    { lib, pkgs, ... }:
    let
      hermes = env { inherit lib pkgs; };
    in
    {
      home.packages = hermes.packages;
      home.sessionVariables = hermes.sessionVariables;
    };

  flake.modules.nixos.without-home-manager =
    { lib, pkgs, ... }:
    let
      hermes = env { inherit lib pkgs; };
    in
    {
      # CUA's Linux accessibility backend uses AT-SPI, which talks over D-Bus.
      services.dbus.enable = true;

      users.users.sylvester.packages = hermes.packages;

      # NixOS has no per-user session variables; scope a /etc/profile snippet.
      environment.loginShellInit = ''
        if [ "$USER" = 'sylvester' ]; then
          export HERMES_TUI="${hermes.sessionVariables.HERMES_TUI}"
          export AGENT_BROWSER_EXECUTABLE_PATH='${hermes.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH}'
        fi
      '';
    };
}
