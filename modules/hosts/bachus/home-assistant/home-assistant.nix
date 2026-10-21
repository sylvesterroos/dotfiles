{ inputs, ... }:
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      stateDir = "/var/lib/proton-drive";
      # On the /srv disk; the config volume stays on the root disk.
      backupsDir = "/srv/backups/home-assistant";

      # The Proton Drive CLI, signed in to this host's Proton account. Its
      # session sits in stateDir as auth-session.json, which unlocks the
      # account: keep that folder out of backups. Sign in once with
      # `sudo proton-drive auth login`.
      proton-drive =
        pkgs.runCommand "proton-drive"
          {
            nativeBuildInputs = [ pkgs.makeWrapper ];
            meta.mainProgram = "proton-drive";
          }
          ''
            makeWrapper ${lib.getExe pkgs.proton-drive-cli} $out/bin/proton-drive \
              --set PROTON_DRIVE_CREDENTIALS_STORE unsafe_file \
              --set PROTON_DRIVE_CACHE_DIR ${stateDir} \
              --set PROTON_DRIVE_LOG_LEVEL WARNING
          '';
    in
    {
      # HA binds 0.0.0.0 (host network), so the firewall allows LAN clients to reach it directly;
      networking.firewall.allowedTCPPorts = [ 8123 ];

      # Hermes' Home Assistant gateway platform and ha_* tools.
      my.hermes-agent.plugins = [ "${inputs.self}/pkgs/hermes-plugin-homeassistant" ];

      virtualisation.oci-containers.containers.homeassistant = {
        volumes = [
          "home-assistant:/config"
          "${backupsDir}:/config/backups"
        ];
        environment.TZ = config.time.timeZone;
        image = "ghcr.io/home-assistant/home-assistant:stable";
        labels."io.containers.autoupdate" = "registry";
        extraOptions =
          let
            zigbeeDongleDevice = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_62e4d8598c12f011b2b8fd13773d9da9-if00-port0";
          in
          [
            # Use the host network namespace for all sockets
            "--network=host"
            # Pass devices into the container, so Home Assistant can discover and make use of them
            "--device=${zigbeeDongleDevice}:${zigbeeDongleDevice}"
          ];
      };

      # Home Assistant's automatic backups (Settings → System → Backups) land in
      # backupsDir; this copies them to Proton Drive daily.
      environment.systemPackages = [ proton-drive ];
      systemd.tmpfiles.settings.home-assistant-backups = {
        ${stateDir}.d.mode = "0700";
        ${backupsDir}.d.mode = "0700";
      };
      systemd.services.podman-homeassistant.unitConfig.RequiresMountsFor = backupsDir;

      systemd.services.home-assistant-backup-upload = {
        description = "Copy Home Assistant backups to Proton Drive";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        unitConfig = {
          RequiresMountsFor = backupsDir;
          # Four attempts per day's run; a failure that outlasts them waits for
          # the next timer.
          StartLimitIntervalSec = "2h";
          StartLimitBurst = 4;
        };
        environment = {
          PROTON_DRIVE = lib.getExe proton-drive;
          BACKUPS = backupsDir;
          REMOTE = "/my-files/homelab/backups/home-assistant";
          KEEP = "14";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writers.writeNu "home-assistant-backup-upload" { } ./backup-upload.nu;
          Restart = "on-failure";
          RestartSec = "15min";
        };
      };

      # Runs after Home Assistant's automatic backup, which starts between 04:45
      # and 05:45.
      systemd.timers.home-assistant-backup-upload = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "07:00";
          Persistent = true;
        };
      };
    };
}
