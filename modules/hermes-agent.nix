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
      llmAgents = inputs.llm-agents.packages.${system};
      hermesPkgs = inputs.llm-agents.inputs.nixpkgs.legacyPackages.${system};
      python = hermesPkgs.python3;
      hermes = llmAgents.hermes-agent.overridePythonAttrs (
        old:
        let
          dependencies =
            old.dependencies
            ++ map (path: hermesPkgs.callPackage path { pythonPackages = python.pkgs; }) (
              [ "${inputs.self}/pkgs/hermes-plugin-hindsight" ] ++ plugins
            )
            # The hermes-relay plugin, installed in the synced profiles, imports
            # these beyond Hermes' own dependencies.
            ++ (with python.pkgs; [
              segno
              websocket-client
            ]);
          # The CLI and its TUI/gateway subprocesses share these dependencies.
          originalPython = python.withPackages (_: old.dependencies);
          runtimePython = python.withPackages (_: dependencies);
        in
        {
          inherit dependencies;
          makeWrapperArgs = map (
            arg: if arg == "${originalPython}/bin/python3" then "${runtimePython}/bin/python3" else arg
          ) old.makeWrapperArgs;
        }
      );
    in
    {
      packages = [
        hermes
        # Desktop launches this same plugin-enabled Hermes build.
        (llmAgents.hermes-desktop.override { hermes-agent = hermes; })
        llmAgents.agent-browser
        llmAgents.claude-code # Anthropic authentication
        pkgs.imagemagick
      ];

      sessionVariables = {
        HERMES_TUI = "1";
        AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
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

  # `hermes gateway install` writes the gateway unit with an FHS PATH. The
  # gateway launches MCP servers (`nix run …`) with that PATH, so this drop-in
  # gives it the user's NixOS tools; the installer rewrites only the unit file.
  flake.modules.nixos.hermes-gateway = {
    systemd.user.services.hermes-gateway = {
      overrideStrategy = "asDropin";
      # Each entry contributes its bin directory.
      path = [
        "/run/wrappers"
        "/etc/profiles/per-user/%u"
        "/run/current-system/sw"
        "%h/.hermes/node"
        "%h/.local"
      ];
    };
  };

  # The Discord bot connects from bachus alone. Its token arrives on the
  # desktops with the synced `.env`, so their gateways pin the adapter off
  # through Hermes' managed scope, which overlays every profile's config.
  # The token stays, so the Discord tools still send from the desktops.
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      environment.etc."hermes/config.yaml".source =
        (pkgs.formats.yaml { }).generate "hermes-managed.yaml"
          {
            platforms.discord.enabled = false;
          };
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
      users.users.sylvester.packages = hermes.packages;

      # NixOS has no per-user session variables; scope a /etc/profile snippet.
      environment.loginShellInit = ''
        if [ "$USER" = 'sylvester' ]; then
          export HERMES_TUI="${hermes.sessionVariables.HERMES_TUI}"
          export AGENT_BROWSER_EXECUTABLE_PATH='${hermes.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH}'
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
