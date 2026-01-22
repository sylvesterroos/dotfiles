{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.foliate;
in
{
  options.my.foliate = {
    enable = mkEnableOption "foliate" // {
      default = pkgs.stdenv.isLinux;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.foliate ];

    home.activation.foliateSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
      FOLIATE_STORAGE="$HOME/.local/share/com.github.johnfactotum.Foliate"
      BACKUP_DIR="$HOME/Miscellaneous/foliate-backup"
      HOSTNAME="$(${pkgs.hostname-debian}/bin/hostname)"

      # Create backup directory if it doesn't exist
      mkdir -p "$BACKUP_DIR"

      # If the storage path exists and is not a symlink, move it to hostname subdirectory
      if [ -e "$FOLIATE_STORAGE" ] && [ ! -L "$FOLIATE_STORAGE" ]; then
        HOSTNAME_BACKUP="$BACKUP_DIR/$HOSTNAME"
        echo "Moving existing Foliate data to $HOSTNAME_BACKUP"
        mkdir -p "$HOSTNAME_BACKUP"
        cp -r "$FOLIATE_STORAGE"/{*,.*} "$HOSTNAME_BACKUP/" 2>/dev/null || true
        rm -rf "$FOLIATE_STORAGE"
      fi

      # Create symlink if it doesn't exist or is not pointing to the right place
      if [ ! -L "$FOLIATE_STORAGE" ] || [ "$(readlink "$FOLIATE_STORAGE")" != "$BACKUP_DIR" ]; then
        echo "Creating symlink from $FOLIATE_STORAGE to $BACKUP_DIR"
        ln -sfn "$BACKUP_DIR" "$FOLIATE_STORAGE"
      fi
    '';
  };
}
