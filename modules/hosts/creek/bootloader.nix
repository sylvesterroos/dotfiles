{
  flake.modules.nixos.creek = {
    boot.kernel.sysctl = {
      # enable SysRq shortcuts
      "kernel.sysrq" = 1;
    };

    boot.loader.systemd-boot = {
      enable = true;
      consoleMode = "keep";
      memtest86.enable = true;
    };
    boot.loader.efi.canTouchEfiVariables = true;
    # 0 = menu hidden, boots silently; hold space/esc/arrows at power-on to enter it
    boot.loader.timeout = 0;

    # Setup keyfile
    boot.initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };

    # boot splash screen
    boot.plymouth = {
      enable = true;
    };
  };
}
