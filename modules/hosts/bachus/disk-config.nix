{
  flake.modules.nixos.bachus = {
    boot.supportedFilesystems = [ "bcachefs" ];

    disko.devices = {
      disk = {
        root = {
          type = "disk";
          device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S2RBNX0H800595B";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              root = {
                size = "100%";
                content = {
                  type = "bcachefs";
                  filesystem = "fs";
                  label = "root";
                  extraFormatArgs = [
                    "--compression=lz4"
                    "--background_compression=zstd:5"
                  ];
                };
              };
            };
          };
        };

        srv = {
          type = "disk";
          device = "/dev/disk/by-id/usb-TOSHIBA_External_USB_3.0_20190606007936F-0:0";
          content = {
            type = "gpt";
            partitions = {
              srv = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "bcachefs";
                  mountpoint = "/srv";
                  mountOptions = [
                    "relatime"
                    "nofail"
                  ];
                  extraArgs = [
                    "--compression=lz4"
                    "--background_compression=zstd:5"
                  ];
                };
              };
            };
          };
        };

        immich = {
          type = "disk";
          device = "/dev/disk/by-id/usb-Micron_CT1000X9SSD9_2514E8D3DA3F-0:0";
          content = {
            type = "gpt";
            partitions = {
              immich = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "bcachefs";
                  mountpoint = "/srv/media/immich";
                  mountOptions = [
                    "relatime"
                    "nofail"
                  ];
                  extraArgs = [
                    "--compression=lz4"
                    "--background_compression=zstd:5"
                  ];
                };
              };
            };
          };
        };
      };

      bcachefs_filesystems = {
        fs = {
          type = "bcachefs_filesystem";
          subvolumes = {
            "subvolumes/root" = {
              mountpoint = "/";
              mountOptions = [ "relatime" ];
            };
            "subvolumes/home" = {
              mountpoint = "/home";
              mountOptions = [ "relatime" ];
            };
            "subvolumes/nix" = {
              mountpoint = "/nix";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };
}
