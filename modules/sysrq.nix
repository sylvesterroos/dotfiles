# Every Magic SysRq function, so a frozen desktop recovers from the keyboard:
# Alt+SysRq+F to kill the memory hog, R-E-I-S-U-B for a clean reboot.
{
  flake.modules.nixos.desktop = {
    boot.kernel.sysctl."kernel.sysrq" = 1;
  };
}
