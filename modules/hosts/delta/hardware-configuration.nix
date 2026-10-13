# Hardware detected by nixos-generate-config at install time: kernel modules,
# boot-critical filesystems, CPU. Disks added later live in filesystems.nix.
{
  flake.modules.nixos.delta =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/ebe0a7e2-15f3-4c51-920d-b6624675b9d5";
        fsType = "xfs";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/FA69-C56D";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
