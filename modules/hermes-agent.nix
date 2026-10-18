# Hermes Agent: what a user needs to run it, and the profiles every machine
# shares. Each host installs Hermes; the desktops and bachus keep the same
# agents through Syncthing, with long-term memory in Hindsight.
{ inputs, ... }:
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
      cuaDriver = inputs.cua.packages.${system}.cua-driver;
      llmAgents = inputs.llm-agents.packages.${system};
      hermes = hermesBase.override {
        extraPythonPackages = map (
          path: hermesPkgs.callPackage path { pythonPackages = hermesBase.python.pkgs; }
        ) ([ "${inputs.self}/pkgs/hermes-plugin-hindsight" ] ++ plugins);
      };
    in
    {
      packages = [
        hermes
        # Built from the same package, so the desktop app runs this hermes.
        hermes.hermesDesktop
        llmAgents.agent-browser
        llmAgents.claude-code # Anthropic authentication
        cuaDriver
        pkgs.imagemagick
        pkgs.at-spi2-core
      ];

      sessionVariables = {
        HERMES_TUI = "1";
        AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
        HERMES_CUA_DRIVER_CMD = lib.getExe cuaDriver;
      };
    };

  # What makes up a profile, relative to its root (`~/.hermes` for the
  # default profile, `~/.hermes/profiles/<name>` for the others). The default
  # profile and every named profile sync the same parts.
  synced = [
    "config.yaml"
    ".env"
    "SOUL.md"
    "skills"
    "memories"
    "plugins"
    "hindsight"
  ];
  # Churn inside synced paths: usage counters, locks, curator state, caches.
  local = [
    "skills/.usage.json"
    "skills/.locks"
    "skills/.curator_*"
    "skills/.hub/{audit.log,index-cache,quarantine,scan-cache}"
  ];
  roots = [
    "/"
    "/profiles/*/"
  ];
  under = paths: builtins.concatMap (root: map (path: root + path) paths) roots;

  # Everything outside `synced` (databases, sessions, logs, caches, cron jobs
  # and per-device credentials) stays on its machine. The first matching
  # pattern wins. Syncthing only descends into directories it includes, so
  # `profiles` is included and each profile's unlisted entries are ignored.
  profiles = {
    path = "~/.hermes";
    ignorePatterns = [
      "(?d)**.lock"
      "(?d)__pycache__"
    ]
    ++ map (path: "(?d)" + path) (under local)
    ++ map (path: "!" + path) (under synced)
    ++ [
      "/profiles/*/*"
      "!/profiles"
      "*"
    ];
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
          export HERMES_CUA_DRIVER_CMD='${hermes.sessionVariables.HERMES_CUA_DRIVER_CMD}'
        fi
      '';
    };

  flake.modules.homeManager.desktop.services.syncthing.settings.folders.hermes = profiles // {
    devices = [ "server" ];
  };

  flake.modules.nixos.bachus.services.syncthing.settings.folders.hermes = profiles // {
    devices = [
      "creek"
      "delta"
    ];
  };
}
