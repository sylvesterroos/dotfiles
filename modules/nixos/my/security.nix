{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.security;
in
{
  options.my.security = {
    enable = mkEnableOption "security" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    security.sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    # Loupe doesn't work with 'graphene-hardened*'
    # environment.memoryAllocator.provider = "graphene-hardened-light";
  };
}
