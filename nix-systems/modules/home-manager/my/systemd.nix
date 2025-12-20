{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.my.systemd-services;
in {
  options.my.systemd-services = {
    enable =
      mkEnableOption "systemd-services"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable (lib.mkIf pkgs.stdenv.isLinux {
    systemd.user = let
      foliateBackupServiceName = "foliate-backup";
    in {
      paths = {
        ${foliateBackupServiceName} = {
          Unit = {
            Description = "Monitor Foliate JSON annotations for changes";
          };
          Path = {
            PathChanged = "%h/.var/app/com.github.johnfactotum.Foliate/data/com.github.johnfactotum.Foliate/";
          };
          Install = {
            WantedBy = ["default.target"];
          };
        };
      };

      services = {
        ${foliateBackupServiceName} = {
          Unit = {
            Description = "Backup Foliate JSON annotations";
            After = ["network.target"];
          };
          Service = {
            Type = "oneshot";

            ExecStart =
              pkgs.writeShellScript foliateBackupServiceName
              # bash
              ''
                set -e
                BACKUP_DIR="$HOME/Miscellaneous/foliate-annotations"
                mkdir -p "$BACKUP_DIR" && \
                find "$HOME/.var/app/com.github.johnfactotum.Foliate/data/com.github.johnfactotum.Foliate" \
                  -maxdepth 1 -name "*.json" -exec cp -t "$BACKUP_DIR/" {} + && \
                date "+%Y-%m-%d %H:%M:%S %Z by systemd foliate-backup.service" > "$BACKUP_DIR/last_backup"
              '';
          };
        };
      };
    };
  });
}
