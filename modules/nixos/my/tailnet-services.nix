{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.tailnet-services;

  servicesJson = pkgs.writeText "tailnet-services.json" (
    builtins.toJSON (
      map (s: {
        name = s.name;
        target = s.target;
      }) cfg.services
    )
  );

  applyScript = pkgs.writers.writeNu "tailnet-services-apply" {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath [ config.services.tailscale.package ]}"
      "--set"
      "SERVICES_JSON"
      "${servicesJson}"
    ];
  } ./scripts/tailnet-services-apply.nu;
in
{
  options.my.tailnet-services = {
    services = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Service name; reachable as <name>.<tailnet>.ts.net inside the tailnet.";
            };
            target = mkOption {
              type = types.str;
              description = "Local address the traffic is proxied to, e.g. 127.0.0.1:8096.";
            };
            headscale = mkOption {
              type = types.bool;
              default = false;
              description = "Also publish the service on the headscale tailnet.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Tailscale Services hosted on this node. The service definition (MagicDNS
        name, TailVIP, endpoint port) lives in the Tailscale admin console;
        this list maps each service to its local target and pushes the serve
        config on every boot and rebuild.
      '';
    };
  };

  config = mkIf (cfg.services != [ ]) {
    systemd.services.tailnet-services-apply = {
      description = "Apply declarative Tailscale Services serve config";
      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # set-config writes are root-gated by tailscaled's local API, which is
        # what makes this unit the only writer of the node's serve config.
        ExecStart = applyScript;
      };
    };
  };
}
