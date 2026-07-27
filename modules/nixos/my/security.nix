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
    security.run0 = {
      enable = true;
      sudo-shim.enable = true;
    };
    system.tools.nixos-rebuild.enableRun0Elevation = true;

    security.sudo.enable = false;
    security.sudo-rs.enable = false;

    # Loupe doesn't work with 'graphene-hardened*'
    # environment.memoryAllocator.provider = "graphene-hardened-light";

    networking.firewall.allowedTCPPorts = cfg.openTCPPorts;
  };
}
