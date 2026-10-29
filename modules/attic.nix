# Attic binary cache on bachus: every host substitutes from it, the desktops
# push their store paths to it, bachus serves it on the tailnet.
{ config, lib, ... }:
let
  host = "bachus";
  port = 18732;
  endpoint = "http://${host}.allosaurus-snapper.ts.net:${toString port}/";
  # Each host signs its own builds with a key named after it.
  hostKeyNames = lib.attrNames config.configurations.nixos;
in
{
  flake.modules.nixos.base = {
    # Prefer public caches; use Bachus for locally built store paths.
    nix.settings.substituters = lib.mkAfter [ "${endpoint}bachus?priority=100" ];
    nix.settings.trusted-public-keys = [ "bachus:S4UzuyjTb539BS1RcIeaGlrsZSRl2Ae+m5VtJ9lTKA8=" ];
  };

  flake.modules.nixos.desktop =
    { config, ... }:
    {
      sops.secrets."attic/token".owner = config.users.users.sylvester.name;
    };

  flake.modules.homeManager.desktop =
    { osConfig, ... }:
    {
      programs.attic-client = {
        enable = true;
        settings = {
          default-server = host;
          servers.${host} = {
            inherit endpoint;
            token-file = osConfig.sops.secrets."attic/token".path;
          };
        };
        watchStore = [ host ];
      };
    };

  flake.modules.nixos.attic-server =
    { config, pkgs, ... }:
    let
      serverConfig = (pkgs.formats.toml { }).generate "server.toml" config.services.atticd.settings;
    in
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

      # Pushers skip paths signed by an upstream key: those caches serve them
      # already, so the cache holds only what the hosts build themselves.
      # Every key the Nix daemon trusts is upstream except the host keys; the
      # daemon's effective config also carries the keys determinate-nixd adds
      # at runtime. The list lives in atticd's database and changes only
      # through its API, so this unit sets it on every activation. A configure
      # call also sets the retention period; passing none keeps the global
      # garbage-collection default.
      systemd.services.atticd-configure-cache = {
        description = "Set the upstream cache keys of the ${host} attic cache";
        wantedBy = [ "multi-user.target" ];
        after = [ "atticd.service" ];
        requires = [ "atticd.service" ];
        path = [
          config.services.atticd.package
          config.nix.package
          pkgs.attic-client
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          DynamicUser = true;
          RuntimeDirectory = "atticd-configure-cache";
          EnvironmentFile = config.services.atticd.environmentFile;
          # atticd may still be binding its port when this unit starts.
          Restart = "on-failure";
          RestartSec = 5;
        };

        script = ''
          export XDG_CONFIG_HOME="$RUNTIME_DIRECTORY"
          token=$(atticadm -f ${serverConfig} make-token --sub atticd-configure-cache --validity 5m \
            --configure-cache ${host} --configure-cache-retention ${host})
          mkdir -p "$XDG_CONFIG_HOME/attic"
          printf 'default-server = "local"\n[servers.local]\nendpoint = "http://127.0.0.1:${toString port}/"\ntoken = "%s"\n' \
            "$token" > "$XDG_CONFIG_HOME/attic/config.toml"

          upstream=()
          for key in $(nix config show trusted-public-keys); do
            name=''${key%%:*}
            case " ${toString hostKeyNames} " in
              *" $name "*) ;;
              *) upstream+=(--upstream-cache-key-name "$name") ;;
            esac
          done
          attic cache configure ${host} "''${upstream[@]}"
        '';
      };

      my.tailnet-services.services = [
        {
          name = "attic";
          routes."/" = "http://127.0.0.1:${toString port}";
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
