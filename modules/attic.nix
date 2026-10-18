# Attic binary cache on bachus: every host substitutes from it, the desktops
# push their store paths to it, bachus serves it on the tailnet.
{ lib, ... }:
let
  host = "bachus";
  port = 18732;
  endpoint = "http://${host}.allosaurus-snapper.ts.net:${toString port}/";
in
{
  flake.modules.nixos.base = {
    # Prefer public caches; use Bachus for locally built store paths.
    nix.settings.substituters = lib.mkAfter [ "${endpoint}bachus?priority=100" ];
    nix.settings.trusted-public-keys = [ "bachus:S4UzuyjTb539BS1RcIeaGlrsZSRl2Ae+m5VtJ9lTKA8=" ];
  };

  flake.modules.homeManager.desktop =
    { config, osConfig, ... }:
    let
      token = "attic/tokens/${osConfig.networking.hostName}";
    in
    {
      sops.secrets.${token} = { };

      programs.attic-client = {
        enable = true;
        settings = {
          default-server = host;
          servers.${host} = {
            inherit endpoint;
            token-file = config.sops.secrets.${token}.path;
          };
        };
        watchStore = [ host ];
      };

      systemd.user.services."attic-watch-store--${host}".Unit.After = [ "sops-nix.service" ];
    };

  flake.modules.nixos.attic-server =
    { config, ... }:
    {
      sops.secrets."atticd/rs256_secret" = { };

      sops.templates."atticd.env".content = ''
        ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."atticd/rs256_secret"}
      '';

      services.atticd = {
        enable = true;
        environmentFile = config.sops.templates."atticd.env".path;
        settings = {
          listen = "[::]:${toString port}";
          jwt = { };
          garbage-collection = {
            interval = "12h";
            default-retention-period = "30d";
          };
        };
      };

      my.tailnet-services.services = [
        {
          name = "attic";
          target = "http://127.0.0.1:${toString port}";
        }
      ];

      # Tailnet-only: reachable through tailscale0 and nowhere else.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

      assertions = [
        {
          assertion = !lib.elem port config.networking.firewall.allowedTCPPorts;
          message = "atticd: ${toString port} must stay out of networking.firewall.allowedTCPPorts — it is tailnet-only via tailscale0";
        }
        {
          assertion =
            !(lib.any (iface: lib.elem port iface.allowedTCPPorts) (
              lib.attrValues (removeAttrs config.networking.firewall.interfaces [ "tailscale0" ])
            ));
          message = "atticd: ${toString port} must stay closed on every interface except tailscale0";
        }
      ];
    };
}
