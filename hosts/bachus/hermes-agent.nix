{
  pkgs,
  lib,
  config,
  ...
}:
let
  userName = "sylvester";
  user = config.users.users.${userName};
  userUid = toString user.uid;
  userGid = toString config.users.groups.users.gid;

  imageName = "docker.io/nousresearch/hermes-agent:latest";
  containerName = "hermes-agent";
  containerNameDashboard = "hermes-dashboard";
  networkName = "hermes-net";

  containerDataDir = "/opt/data";
  containerHomeDir = "/home/hermes";

  containerBin = lib.getExe pkgs.podman;
  coreutilsBin = "${pkgs.coreutils}/bin";
  startScriptHashDir = "${user.home}/.local/state/hermes/systemd";

  volumes = [
    "/etc/nixos:/dotfiles:rw"
    "${user.home}/Code:/Code:rw"
    "${user.home}/PARA:/PARA:rw"
    "${user.home}/.local/state/hermes/home:${containerHomeDir}:rw"
    "${user.home}/.local/state/hermes/hermes:${containerDataDir}:rw"
  ];

  mkStartScriptChangePreStart =
    container: scriptPath:
    pkgs.writeShellScript "hermes-${container}-recreate-if-script-changed" ''
      state_dir=${lib.escapeShellArg startScriptHashDir}
      hash_file="$state_dir/${container}.start-script.sha256"
      current_hash="$(${coreutilsBin}/sha256sum ${lib.escapeShellArg scriptPath} | ${coreutilsBin}/cut -d ' ' -f1)"

      mkdir -p "$state_dir"

      if [ -f "$hash_file" ]; then
        previous_hash="$(<"$hash_file")"
        if [ "$previous_hash" != "$current_hash" ]; then
          echo "Start script changed for ${container}; removing existing container"
          ${containerBin} rm -f ${container} >/dev/null 2>&1 || true
        fi
      elif ${containerBin} container exists ${container}; then
        echo "No recorded start script hash for ${container}; removing existing container"
        ${containerBin} rm -f ${container} >/dev/null 2>&1 || true
      fi

      printf '%s\n' "$current_hash" > "$hash_file"
    '';

  startScript = pkgs.writeShellScript "hermes-start" ''
    if ${containerBin} container exists ${containerName}; then
        echo "Container ${containerName} exists, starting it"
        exec ${containerBin} start ${containerName}
    else
        echo "Container ${containerName} does not exist, creating it"
        host_uid="${userUid}"
        host_gid="${userGid}"

        ${containerBin} create \
          --name=${containerName} \
          --pull=never \
          --restart=unless-stopped \
          --userns=keep-id \
          --user="$host_uid:$host_gid" \
          --env HERMES_UID="$host_uid" \
          --env HERMES_GID="$host_gid" \
          --env HOME=${containerHomeDir} \
          ${lib.concatStringsSep " " (map (v: "--volume ${lib.escapeShellArg v}") volumes)} \
          --cpus=2 --memory=4G \
          -p 8642:8642 \
          --network-alias=${containerName} \
          --network=${networkName} \
          ${imageName} \
          gateway run

        exec ${containerBin} start ${containerName}
    fi
  '';

  startScriptDashboard = pkgs.writeShellScript "hermes-dashboard-start" ''
    if ${containerBin} container exists ${containerNameDashboard}; then
        echo "Container ${containerNameDashboard} exists, starting it"
        exec ${containerBin} start ${containerNameDashboard}
    else
        echo "Container ${containerNameDashboard} does not exist, creating it"
        host_uid="${userUid}"
        host_gid="${userGid}"

        ${containerBin} create \
          --name=${containerNameDashboard} \
          --pull=never \
          --restart=unless-stopped \
          --userns=keep-id \
          --user="$host_uid:$host_gid" \
          --env HERMES_UID="$host_uid" \
          --env HERMES_GID="$host_gid" \
          --env HOME=${containerHomeDir} \
          --env GATEWAY_HEALTH_URL=http://${containerName}:8642 \
          ${lib.concatStringsSep " " (map (v: "--volume ${lib.escapeShellArg v}") volumes)} \
          --cpus=0.5 --memory=512M \
          -p 9119:9119 \
          --network-alias=${containerNameDashboard} \
          --network=${networkName} \
          ${imageName} \
          dashboard --host 0.0.0.0 --insecure

        exec ${containerBin} start ${containerNameDashboard}
    fi
  '';

  startScriptPre = mkStartScriptChangePreStart containerName startScript;
  startScriptDashboardPre = mkStartScriptChangePreStart containerNameDashboard startScriptDashboard;
in
{
  assertions = [
    {
      assertion = user.linger == true;
      message = "hermes-agent: user ${userName} must have linger enabled for user services to start at boot. Set users.users.${userName}.linger = true;";
    }
  ];

  systemd.user.services."hermes-agent" = {
    unitConfig.ConditionUser = userName;
    serviceConfig = {
      # podman start forks and exits; forking tells systemd to expect that.
      Type = "forking";
      ExecStartPre = startScriptPre;
      ExecStart = startScript;
      ExecStop = "${containerBin} stop ${containerName}";
      Restart = "on-failure";
      RestartSec = "5";
      TimeoutStopSec = 30;
    };
    path = [
      "/run/wrappers"
    ];
    after = [
      "podman-network-${networkName}.service"
    ];
    requires = [ "podman-network-${networkName}.service" ];
    wantedBy = [ "default.target" ];
  };

  systemd.user.services."hermes-dashboard" = {
    unitConfig.ConditionUser = userName;
    serviceConfig = {
      Type = "forking";
      ExecStartPre = startScriptDashboardPre;
      ExecStart = startScriptDashboard;
      ExecStop = "${containerBin} stop ${containerNameDashboard}";
      Restart = "on-failure";
      RestartSec = "5";
      TimeoutStopSec = 30;
    };
    path = [
      "/run/wrappers"
    ];
    # after = [ "hermes-agent.service" ];
    # requires = [ "hermes-agent.service" ];
    wantedBy = [ "default.target" ];
  };

  systemd.user.services."podman-network-${networkName}" = {
    unitConfig.ConditionUser = userName;
    path = [
      "/run/wrappers"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${containerBin} network rm -f ${networkName}";
    };
    script = ''
      ${containerBin} network inspect ${networkName} || ${containerBin} network create --driver bridge ${networkName}
    '';
  };

  systemd.user.services."podman-pull-hermes-agent" = {
    unitConfig.ConditionUser = userName;
    path = [
      "/run/wrappers"
    ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${containerBin} pull ${imageName}

      CONTAINER_IMAGE=$(${containerBin} inspect ${containerName} --format '{{.Image}}' 2>/dev/null || echo "")
      LATEST_IMAGE=$(${containerBin} inspect ${imageName} --format '{{.Id}}' 2>/dev/null || echo "")

      if [ -n "$CONTAINER_IMAGE" ] && [ -n "$LATEST_IMAGE" ] && [ "$CONTAINER_IMAGE" != "$LATEST_IMAGE" ]; then
        echo "New image detected, recreating containers..."
        ${containerBin} rm -f ${containerName} || true
        systemctl --user restart hermes-agent.service
      else
        echo "Image is up to date"
      fi
    '';
    wantedBy = [ "podman-pull-hermes-agent.timer" ];
  };

  systemd.user.timers."podman-pull-hermes-agent" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
