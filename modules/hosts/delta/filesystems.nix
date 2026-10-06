{
  flake.modules.nixos.delta =
    { lib, ... }:
    {
      # mkForce is needed to override the hardware-configuration value?
      fileSystems."/home/sylvester/Games" = lib.mkForce {
        device = "/dev/disk/by-label/Linux_Games";
        fsType = "xfs";
        options = [
          "nofail"
          "nodiratime"
        ];
      };

      # Shared Steam library with Windows.
      # Ownership is forced to sylvester since NTFS carries none.
      fileSystems."/mnt/win-games" = {
        device = "/dev/disk/by-label/Windows_Games";
        fsType = "ntfs-3g";
        options = [
          "uid=1000"
          "gid=100"
          "windows_names"
          "nofail"
          "x-systemd.device-timeout=5s"
        ];
      };

      fileSystems."/mnt/win-c" = {
        device = "/dev/disk/by-uuid/DEF21E9FF21E7C49";
        fsType = "ntfs-3g";
        options = [
          "uid=1000"
          "gid=100"
          "windows_names"
          "nofail"
          "x-systemd.device-timeout=5s"
        ];
      };

      systemd.services.steam-compatdata = {
        description = "Symlink NTFS Steam libraries' compatdata onto a Linux filesystem";
        wantedBy = [ "multi-user.target" ];
        requires = [
          "mnt-win\\x2dgames.mount"
          "mnt-win\\x2dc.mount"
        ];
        after = [
          "mnt-win\\x2dgames.mount"
          "mnt-win\\x2dc.mount"
        ];

        serviceConfig = {
          Type = "oneshot";
          User = "sylvester";
        };

        script = ''
          compat=/home/sylvester/.local/share/Steam/steamapps/compatdata
          mkdir -p "$compat"
          ln -sfn "$compat" '/mnt/win-games/SteamLibrary/steamapps/compatdata'
          ln -sfn "$compat" '/mnt/win-c/Program Files (x86)/Steam/steamapps/compatdata'
        '';
      };
    };
}
