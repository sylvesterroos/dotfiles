{
  flake.modules.nixos.delta =
    { lib, ... }:
    let
      # Steam library folders on NTFS, shared with Windows.
      ntfsSteamLibraries = {
        win-games = "/mnt/win-games/SteamLibrary";
        win-c = "/mnt/win-c/Program Files (x86)/Steam";
      };

      # In-kernel ntfs3 driver. Ownership is forced to sylvester since NTFS carries none.
      ntfsMount = device: {
        inherit device;
        fsType = "ntfs3";
        options = [
          "uid=1000"
          "gid=100"
          "windows_names"
          "nofail"
          "x-systemd.device-timeout=5s"
        ];
      };
    in
    {
      fileSystems."/home/sylvester/Games" = {
        device = "/dev/disk/by-label/Linux_Games";
        fsType = "xfs";
        options = [
          "nofail"
          "noatime"
        ];
      };

      fileSystems."/mnt/win-games" = ntfsMount "/dev/disk/by-label/Windows_Games";
      fileSystems."/mnt/win-c" = ntfsMount "/dev/disk/by-uuid/DEF21E9FF21E7C49";

      # Proton prefixes contain names NTFS can't hold, so each library's compatdata
      # points at one shared directory on a Linux filesystem. One unit per library,
      # so a volume that fails to mount leaves the others linked.
      systemd.services = lib.mapAttrs' (
        name: library:
        lib.nameValuePair "steam-compatdata-${name}" {
          description = "Symlink ${library} compatdata onto a Linux filesystem";
          wantedBy = [ "multi-user.target" ];
          unitConfig.RequiresMountsFor = ''"${library}"'';

          serviceConfig = {
            Type = "oneshot";
            User = "sylvester";
          };

          script = ''
            compat=/home/sylvester/.local/share/Steam/steamapps/compatdata
            mkdir -p "$compat"
            ln -sfn "$compat" '${library}/steamapps/compatdata'
          '';
        }
      ) ntfsSteamLibraries;
    };
}
