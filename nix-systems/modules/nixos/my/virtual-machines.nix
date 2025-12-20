{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.virtual-machines;
in {
  options.my.virtual-machines = {
    enable =
      mkEnableOption "virtual-machines"
      // {
        default = false;
      };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          swtpm.enable = true;
          vhostUserPackages = [
            pkgs.virtiofsd
          ];
        };
      };
      spiceUSBRedirection.enable = true;
    };

    environment.systemPackages = with pkgs; [
      virt-manager
      virtio-win
      win-spice
    ];
  };
}
