{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.tailnet-services;

  # Each service becomes a host-local serve entry, and this whole file is the
  # source of truth: `set-config --all` replaces the node's previous serve
  # config on every apply. The node must be a tagged tailnet node and every
  # service must be defined in the admin console (one-time setup).
  serveConfig = pkgs.writeText "tailnet-services-serve.json" (
    builtins.toJSON {
      version = "0.0.1";
      services = builtins.listToAttrs (
        map (
          s:
          lib.nameValuePair "svc:${s.name}" {
            endpoints = {
              "https:443" = "http://${s.target}";
            };
          }
        ) cfg.services
      );
    }
  );

  applyScript = pkgs.writeShellScript "tailnet-services-apply" ''
    set -euo pipefail

    # tailscaled is up per systemd ordering but not always ready to serve yet;
    # bounded retry instead of systemd Restart (Type=oneshot forbids it).
    attempts=12
    until tailscale serve set-config --all ${serveConfig}; do
      attempts=$((attempts - 1))
      if [ "$attempts" -eq 0 ]; then
        echo "tailscale serve set-config kept failing." >&2
        exit 1
      fi
      sleep 10
    done

    # Configuration and advertising are separate steps for Service hosts.
    # Approval depends on the tailnet's auto-approver policy.
    ${lib.concatStringsSep "\n" (
      map (s: ''
        if ! tailscale serve advertise svc:${s.name}; then
          echo "Advertising svc:${s.name} failed." >&2
          echo "Check: node is tagged (tagOwners in the ACL file), svc:${s.name} exists on the admin console Services page, and the services auto-approver rule covers it." >&2
          exit 1
        fi
      '') cfg.services
    )}

    tailscale serve status
  '';
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
