# What a user needs to run Hermes Agent.
{ inputs, mv, ... }:
let
  env =
    {
      lib,
      pkgs,
      plugins,
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      # Plugins must be built for the interpreter Hermes runs, which comes
      # from Hermes' own nixpkgs; extraPythonPackages drops anything else.
      hermesPkgs = inputs.hermes-agent.inputs.nixpkgs.legacyPackages.${system};
      hermesBase = inputs.hermes-agent.packages.${system}.default;
      hermes = hermesBase.override {
        extraPythonPackages = map (
          path: hermesPkgs.callPackage path { pythonPackages = hermesBase.python.pkgs; }
        ) ([ ../pkgs/hermes-plugin-hindsight ] ++ plugins);
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
  flake.modules.nixos.base =
    { lib, ... }:
    {
      options.my.hermes-agent.plugins = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "Hermes plugin package directories this host adds, built against Hermes' Python.";
      };
    };

  flake.modules.homeManager.base =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hermes = env {
        inherit lib pkgs;
        inherit (osConfig.my.hermes-agent) plugins;
      };
    in
    {
      home.packages = hermes.packages;
      home.sessionVariables = hermes.sessionVariables;
    };

  flake.modules.nixos.without-home-manager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hermes = env {
        inherit lib pkgs;
        inherit (config.my.hermes-agent) plugins;
      };
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
