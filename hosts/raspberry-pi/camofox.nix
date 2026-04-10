{
  pkgs,
  config,
  ...
}:
let
  userName = "sylvester";
  user = config.users.users.${userName};

  startScript = pkgs.writeShellScript "camofox-start" ''
    if podman container exists camofox; then
        echo "Container camofox exists, starting it"
        exec podman start camofox
    else
        echo "Container camofox does not exist, creating it"
        podman create \
          --name=camofox \
          --log-driver=journald \
          --pull=never \
          -e CAMOFOX_PORT=9377 \
          -p 9377:9377 \
          --cpus=2 --memory=1G \
          --network=hermes-agent_default \
          --network-alias=camofox \
          localhost/camofox
        exec podman start camofox
    fi
  '';
in
{
  assertions = [
    {
      assertion = user.linger == true;
      message = "camofox: user ${userName} must have linger enabled for user services to start at boot. Set users.users.${userName}.linger = true;";
    }
  ];

  # Container runtime
  systemd.user.services."camofox" = {
    unitConfig.ConditionUser = userName;
    serviceConfig = {
      # podman start forks and exits; forking tells systemd to expect that.
      Type = "forking";
      ExecStart = startScript;
      Restart = "on-failure";
      RestartSec = "5";
    };
    path = [ pkgs.podman "/run/wrappers" ];
    after = [
      "podman-network-hermes-agent_default.service"
      "podman-build-camofox.service"
    ];
    requires = [ "podman-network-hermes-agent_default.service" ];
    wants = [ "podman-build-camofox.service" ];
    wantedBy = [ "default.target" ];
  };

  # Build from upstream Dockerfile, tagged by git release
  systemd.user.services."podman-build-camofox" = {
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
      LAST=$(podman image inspect camofox --format '{{ index .Labels "commit" }}' 2>/dev/null || true)

      LATEST_TAG=$(
        git ls-remote --tags --refs https://github.com/jo-inc/camofox-browser.git \
          | awk -F/ '{print $3}' \
          | sed 's/^v//' \
          | sort -V \
          | tail -n1
      )

      LATEST="refs/tags/v$LATEST_TAG"

      if [ "$LATEST" != "$LAST" ]; then
        podman build \
          --build-arg CAMOUFOX_URL="https://github.com/daijro/camoufox/releases/download/v135.0.1-beta.24/camoufox-135.0.1-beta.24-lin.arm64.zip" \ # Needed for arm64
          --label commit=$LATEST \
          -t camofox \
          https://github.com/jo-inc/camofox-browser.git#$LATEST
      else
        echo "No changes, skipping build"
      fi
    '';
  };

  # Daily rebuild + restart
  systemd.user.services."podman-update-camofox" = {
    unitConfig.ConditionUser = userName;
    after = [ "podman-build-camofox.service" ];
    requires = [ "podman-build-camofox.service" ];
    path = [ pkgs.podman "/run/wrappers" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      systemctl --user restart camofox.service
    '';
    wantedBy = [ "podman-update-camofox.timer" ];
  };

  systemd.user.timers."podman-update-camofox" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
