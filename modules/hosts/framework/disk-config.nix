# The single NVMe drive: EFI, a LUKS2 root unlocked by a FIDO2 key, and swap
# for zswap at the end of the disk. Swap sits directly after root, so root can
# grow over it once bcachefs supports swapfiles.
{
  flake.modules.nixos.framework = {
    boot.supportedFilesystems = [ "bcachefs" ];

    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/nvme0n1";
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
              end = "-16G";
              content = {
                type = "luks";
                name = "root";
                # Enrolls the plugged-in key and prints a recovery key as a QR code.
                enrollFido2 = true;
                settings.allowDiscards = true;
                content = {
                  type = "bcachefs";
                  filesystem = "fs";
                  label = "root";
                };
              };
            };

            swap = {
              size = "100%";
              content = {
                type = "swap";
                # Hibernation is off, so a fresh key each boot is enough.
                randomEncryption = true;
                discardPolicy = "both";
              };
            };
          };
        };
      };

      bcachefs_filesystems.fs = {
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
}
