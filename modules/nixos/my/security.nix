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

    openTCPPorts = mkOption {
      type = with types; listOf (ints.between 1 65535);
      default = [ ];
      description = "Additional TCP ports to open in the host firewall.";
      example = literalExpression "[ 1234 ]";
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

    networking.firewall.allowedTCPPorts = cfg.openTCPPorts;
  };
}
