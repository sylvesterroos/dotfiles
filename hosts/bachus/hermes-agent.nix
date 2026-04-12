{
  pkgs,
  lib,
  config,
  ...
}:
let
  userName = "sylvester";
  user = config.users.users.${userName};

  volumes = [
    "${user.home}/.dotfiles:/dotfiles:rw"
    "${user.home}/Code:/Code:rw"
    "${user.home}/PARA:/PARA:rw"
    "${user.home}/.hermes:/opt/data:rw"
    "${user.home}/.local/state/hermes/home:/root:rw"
  ];

  cmd = [
    "gateway"
    "run"
  ];

  # Start script that preserves container state across restarts.
  # If the container already exists, start it. Otherwise, create it.
  startScript = pkgs.writeShellScript "hermes-start" ''
    if podman container exists hermes; then
        echo "Container hermes exists, starting it"
        exec podman start hermes
    else
        echo "Container hermes does not exist, creating it"
        podman create \
          --name=hermes \
          --log-driver=journald \
          --pull=never \
          --restart=unless-stopped \
          ${lib.concatStringsSep " " (map (v: "-v ${lib.escapeShellArg v}") volumes)} \
          --cpus=2 --memory=1G \
          --network-alias=hermes \
          --network=hermes-agent_default \
          localhost/hermes ${lib.concatStringsSep " " (map lib.escapeShellArg cmd)}

        exec podman start hermes
    fi
  '';
in
{
  # User services need linger to start at boot without an active login session.
  assertions = [
    {
      assertion = user.linger == true;
      message = "hermes-agent: user ${userName} must have linger enabled for user services to start at boot. Set users.users.${userName}.linger = true;";
    }
  ];

  # Container runtime
  systemd.user.services."hermes" = {
    unitConfig.ConditionUser = userName;
    serviceConfig = {
      # podman start forks and exits; forking tells systemd to expect that.
      Type = "forking";
      ExecStart = startScript;
      Restart = "on-failure";
      RestartSec = "5";
    };
    path = [
      pkgs.podman
      "/run/wrappers"
    ];
    after = [
      "podman-network-hermes-agent_default.service"
      "podman-build-hermes.service"
    ];
    requires = [ "podman-network-hermes-agent_default.service" ];
    wants = [ "podman-build-hermes.service" ];
    wantedBy = [ "default.target" ];
  };

  systemd.user.services."podman-network-hermes-agent_default" = {
    unitConfig.ConditionUser = userName;
    path = [
      pkgs.podman
      "/run/wrappers"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f hermes-agent_default";
    };
    script = ''
      podman network inspect hermes-agent_default || podman network create hermes-agent_default
    '';
  };

  # Build and update: check for new release tags, build if needed,
  # and restart the container with the new image.
  systemd.user.services."podman-build-hermes" = {
    unitConfig.ConditionUser = userName;
    path = [
      pkgs.podman
      pkgs.git
      pkgs.gawk
      pkgs.gnused
      pkgs.coreutils
      "/run/wrappers"
    ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      LAST=$(podman image inspect hermes --format '{{ index .Labels "commit" }}' 2>/dev/null || true)

      LATEST_TAG=$(
        git ls-remote --tags --refs https://github.com/NousResearch/hermes-agent.git \
          | awk -F/ '{print $3}' \
          | sed 's/^v//' \
          | sort -V \
          | tail -n1
      )

      LATEST="refs/tags/v$LATEST_TAG"

      if [ "$LATEST" != "$LAST" ]; then
        podman build \
          --label commit=$LATEST \
          -t hermes \
          https://github.com/NousResearch/hermes-agent.git#$LATEST

        podman rm -f hermes || true
        systemctl --user restart hermes.service
      else
        echo "No changes, skipping build and update"
      fi
    '';
    wantedBy = [ "podman-build-hermes.timer" ];
  };

  systemd.user.timers."podman-build-hermes" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
