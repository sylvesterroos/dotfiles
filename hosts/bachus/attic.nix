{ config, lib, ... }:
with lib;
let
  atticShared = import ../../modules/shared/attic.nix { };
in
{
  sops.secrets."atticd/rs256_secret" = { };

  sops.templates."atticd.env" = {
    content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."atticd/rs256_secret"}
    '';
  };

  services.atticd = {
    enable = true;
    environmentFile = config.sops.templates."atticd.env".path;
    settings = {
      listen = atticShared.listen;
      jwt = { };
      garbage-collection = {
        interval = "12h";
        default-retention-period = "30d";
      };
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ atticShared.port ];

  assertions = [
    {
      assertion = !elem atticShared.port config.networking.firewall.allowedTCPPorts;
      message = "atticd: ${toString atticShared.port} must stay out of networking.firewall.allowedTCPPorts — it is tailnet-only via tailscale0";
    }
    {
      assertion =
        !(any (iface: elem atticShared.port iface.allowedTCPPorts) (
          attrValues (removeAttrs config.networking.firewall.interfaces [ "tailscale0" ])
        ));
      message = "atticd: ${toString atticShared.port} must stay closed on every interface except tailscale0";
    }
  ];
}
