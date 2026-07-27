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
    # bachus is on patched nixpkgs-stable (26.05), which predates the
    # rewrite of the `security.run0` module and lacks
    # `system.tools.nixos-rebuild.enableRun0Elevation`. Those landed in
    # nixpkgs 26.11+ (unstable). Gate the new options on nixpkgs >= 26.11
    # so this module keeps building on bachus until nixpkgs-stable reaches 26.11.
    security.run0 = lib.optionalAttrs (lib.versionAtLeast lib.version "26.11") {
      enable = true;
      sudo-shim.enable = true;
    };
    system.tools.nixos-rebuild = lib.optionalAttrs (lib.versionAtLeast lib.version "26.11") {
      enableRun0Elevation = true;
    };

    security.sudo.enable = false;
    security.sudo-rs.enable = false;

    # Loupe doesn't work with 'graphene-hardened*'
    # environment.memoryAllocator.provider = "graphene-hardened-light";

    networking.firewall.allowedTCPPorts = cfg.openTCPPorts;
  };
}
