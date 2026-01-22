{ ... }:
{
  boot.kernel.sysctl = {
    # enable SysRq shortcuts
    "kernel.sysrq" = 1;
  };

  # Bootloader.
  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # boot splash screen
  boot.plymouth = {
    enable = true;
  };
}
