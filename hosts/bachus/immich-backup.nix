# Before first use, initialize the Borg repository:
#   sudo borg init --encryption=none /var/lib/backup/immich-borg
#
# Manual execution:
#   sudo systemctl start borgbackup-job-immich.service
#   sudo systemctl start --no-block immich-backup-proton.service
{
  config,
  pkgs,
  ...
}:
let
  immichMediaLocation = config.services.immich.mediaLocation;
  dbDumpDir = "/var/lib/backup/immich-db-dump";
  borgRepo = "/var/lib/backup/immich-borg";
  rcloneRemotePath = "protondrive:Backups/immich";
in
{
  services.borgbackup.jobs.immich = {
    paths = [
      immichMediaLocation
      dbDumpDir
    ];
    repo = borgRepo;
    # startAt = "daily"; # Disabled automatic scheduling
    compression = "zstd";
    encryption.mode = "none";
    exclude = [
      "${immichMediaLocation}/thumbs"
      "${immichMediaLocation}/encoded-video"
    ];
    preHook = ''
      mkdir -p "${dbDumpDir}"
      ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dump \
        --port=${toString config.services.postgresql.settings.port} \
        --clean --if-exists \
        immich \
        > "${dbDumpDir}/immich-database.sql"
    '';
    prune.keep = {
      weekly = 4;
      monthly = 3;
    };
  };

  systemd.tmpfiles.rules = [ "d ${dbDumpDir} 0700 root root -" ];
  systemd.services."borgbackup-job-immich".serviceConfig.ReadWritePaths = [ dbDumpDir ];

  systemd.services.immich-backup-proton = {
    description = "Sync Immich Borg backup to Proton Drive";
    after = [ "borgbackup-job-immich.service" ];
    wantedBy = [ "borgbackup-job-immich.service" ];

    path = [ pkgs.rclone ];

    script = ''
      export RCLONE_CONFIG_PROTONDRIVE_TYPE=protondrive
      export RCLONE_CONFIG_PROTONDRIVE_USERNAME=$(cat $CREDENTIALS_DIRECTORY/proton-email)
      export RCLONE_CONFIG_PROTONDRIVE_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/proton-rclone-password)

      rclone sync ${borgRepo} ${rcloneRemotePath} \
        --protondrive-replace-existing-draft \
        --transfers 1 \
        --retries 5 \
        --low-level-retries 10 \
        --verbose
    '';

    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "6h";
      LoadCredential = [
        "proton-email:${config.sops.secrets."proton/email".path}"
        "proton-rclone-password:${config.sops.secrets."proton/rclone_obscured_password".path}"
      ];
    };
  };
}
