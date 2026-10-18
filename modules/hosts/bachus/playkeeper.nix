# Playkeeper: a web dashboard for Minecraft Java servers, each one a
# container that the root agent drives through the Docker Engine API, served
# here by rootful podman's socket at /run/docker.sock (modules/podman.nix).
# The panel runs as `playkeeper` and reaches the agent over its Unix socket.
#
# Nix owns what the upstream installer would write: the two units (agent,
# panel), the users, the directories and /etc/playkeeper/config.json.
# Releases come from pkgs/playkeeper; the in-app updater has no unit to hand
# a release to, so updates go through the package version.
#
# The dashboard answers at https://playkeeper.<tailnet>.ts.net
# (tailnet-services.nix). Friends join over the headscale tailnet at
# bachus.<headscale domain>; the headscale policy grants the game ports and
# the userspace headscaled delivers them to loopback. First admin:
# `sudo playkeeper setup-code`.
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      package = pkgs.playkeeper;
      gameUser = "playkeeper-mc";
      # The config carries the game user's ids, so they stay fixed.
      gameId = 950;

      settings = {
        # 8443, the upstream default, belongs to headscaled's Caddy listener.
        panelPort = 8444;
        panelBind = "127.0.0.1";
        gamePort = 25565;
        dataDir = "/var/lib/playkeeper";
        socketPath = "/run/playkeeper/agent.sock";
        dockerSocket = "/run/docker.sock";
        panelUser = "playkeeper";
        gameUID = gameId;
        gameGID = gameId;
        # Labels Playkeeper's containers, network and backups as this machine's.
        installID = "bachus";
        usageStats = "off";
      };
      configFile = "/etc/playkeeper/config.json";
      exe = "${lib.getExe package}";

      # The sandbox upstream gives both units (internal/install/units.go).
      hardening = {
        UMask = "0077";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
        Restart = "on-failure";
        RestartSec = 3;
      };
    in
    {
      environment.systemPackages = [ package ];
      environment.etc."playkeeper/config.json".text = builtins.toJSON settings;

      users.users.${settings.panelUser} = {
        isSystemUser = true;
        group = settings.panelUser;
        home = "${settings.dataDir}/panel";
      };
      users.groups.${settings.panelUser} = { };
      users.users.${gameUser} = {
        isSystemUser = true;
        uid = gameId;
        group = gameUser;
        home = "${settings.dataDir}/server";
      };
      users.groups.${gameUser}.gid = gameId;

      systemd.tmpfiles.rules =
        let
          inherit (settings) dataDir panelUser;
        in
        [
          "d ${dataDir} 0755 root root -"
          "d ${dataDir}/agent 0700 root root -"
          "d ${dataDir}/panel 0700 ${panelUser} ${panelUser} -"
          "d ${dataDir}/servers 0755 root root -"
          "d ${dataDir}/backups 0700 root root -"
          "d ${dataDir}/restore-staging 0700 root root -"
        ];

      systemd.services.playkeeper-agent = {
        description = "Playkeeper agent (local control of the Minecraft containers)";
        after = [
          "podman.socket"
          "network-online.target"
        ];
        requires = [ "podman.socket" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ config.environment.etc."playkeeper/config.json".source ];
        environment.GOMEMLIMIT = "192MiB";
        serviceConfig = hardening // {
          ExecStart = "${exe} agent --config ${configFile}";
          RuntimeDirectory = "playkeeper";
          RuntimeDirectoryMode = "0755";
          ReadWritePaths = [ settings.dataDir ];
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          CapabilityBoundingSet = [
            "CAP_CHOWN"
            "CAP_FOWNER"
            "CAP_DAC_OVERRIDE"
            "CAP_DAC_READ_SEARCH"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
          ];
          MemoryHigh = "256M";
          MemoryMax = "384M";
        };
      };

      systemd.services.playkeeper-panel = {
        description = "Playkeeper web panel (HTTPS)";
        after = [
          "network-online.target"
          "playkeeper-agent.service"
        ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ config.environment.etc."playkeeper/config.json".source ];
        serviceConfig = hardening // {
          User = settings.panelUser;
          Group = settings.panelUser;
          ExecStart = "${exe} panel --config ${configFile}";
          ReadWritePaths = [ "${settings.dataDir}/panel" ];
          PrivateDevices = true;
          MemoryDenyWriteExecute = true;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          CapabilityBoundingSet = "";
          AmbientCapabilities = "";
        };
      };
    };
}
