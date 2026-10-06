# What a user needs to run Hermes Agent.
{ inputs, mv, ... }:
let
  env =
    { lib, pkgs }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      # The plugin must be built for the interpreter Hermes runs, which comes
      # from Hermes' own nixpkgs; extraPythonPackages drops anything else.
      hermesPkgs = inputs.hermes-agent.inputs.nixpkgs.legacyPackages.${system};
      hermes = inputs.hermes-agent.packages.${system}.default.override {
        extraPythonPackages = [ (hermesPkgs.callPackage ../pkgs/hermes-plugin-hindsight { }) ];
      };
    in
    {
      packages = [
        hermes
        # Built from the same package, so the desktop app runs this hermes.
        hermes.hermesDesktop
        mv.tip.agent-browser
        mv.tip.claude-code # Anthropic authentication
        inputs.cua.packages.${system}.cua-driver
        pkgs.imagemagick
        pkgs.at-spi2-core
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
