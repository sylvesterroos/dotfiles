# NetBird's control plane. Clients reach management, signal and relay on one
# public name; the dashboard and its API sit on the personal tailnet. Pocket ID
# is the identity provider for the dashboard and for client logins.
#
# Stable carries every NetBird package and every module except the relay's,
# which comes from tip. The relay module's manual chapter stays behind:
# stable's manual has no redirects for its anchors.
{ config, lib, ... }:
let
  mv = config.multiverse;
  network = config.netbirdNetwork;
in
{
  flake.modules.nixos.bachus =
    { config, ... }:
    let
      cfg = config.services.netbird.server;
      issuer = config.services.pocket-id.settings.APP_URL;
      clientId = "netbird";
      scopes = "openid profile email groups";
      # Where `netbird up` listens for the sign-in result.
      cliRedirects = [
        "http://localhost:53000"
        "http://localhost:54000"
      ];
      dashboardUrl = "https://${network.dashboard}";
      relayAddress = "127.0.0.1:33080";
      dashboardPort = 8090;
      relayUrl = "rels://${network.server}:443/relay";
      relaySecret = config.sops.secrets."netbird/relay_auth_secret".path;
    in
    {
      imports =
        let
          relay = import "${mv.tip.path}/nixos/modules/services/networking/netbird/netbird-relay.nix";
        in
        [ (lib.setFunctionArgs (args: removeAttrs (relay args) [ "meta" ]) (lib.functionArgs relay)) ];

      sops.secrets."netbird/datastore_encryption_key" = { };
      sops.secrets."netbird/relay_auth_secret" = { };

      services.netbird.server = {
        management = {
          enable = true;
          domain = network.server;
          dnsDomain = network.domain;
          oidcConfigEndpoint = "${issuer}/.well-known/openid-configuration";
          settings = {
            DataStoreEncryptionKey._secret = config.sops.secrets."netbird/datastore_encryption_key".path;
            DisableDefaultPolicy = true;
            Stuns = [
              {
                Proto = "udp";
                URI = "stun:stun.cloudflare.com:3478";
                Username = "";
                Password = null;
              }
            ];
            # The relay replaces TURN. The module warns on a literal TURN secret.
            TURNConfig = {
              Turns = [ ];
              Secret._secret = relaySecret;
            };
            Relay = {
              Addresses = [ relayUrl ];
              CredentialsTTL = "24h";
              Secret._secret = relaySecret;
            };
            HttpConfig = {
              AuthIssuer = issuer;
              AuthAudience = clientId;
              AuthKeysLocation = "${issuer}/.well-known/jwks.json";
              AuthUserIDClaim = "sub";
            };
            PKCEAuthorizationFlow.ProviderConfig = {
              Audience = clientId;
              ClientID = clientId;
              AuthorizationEndpoint = "${issuer}/authorize";
              TokenEndpoint = "${issuer}/api/oidc/token";
              Scope = scopes;
              RedirectURLs = cliRedirects;
              UseIDToken = true;
            };
          };
        };

        signal = {
          enable = true;
          domain = network.server;
        };

        dashboard = {
          enable = true;
          domain = network.dashboard;
          managementServer = dashboardUrl;
          settings = {
            # Shown in the dashboard's join instructions; clients use the public name.
            NETBIRD_MGMT_GRPC_API_ENDPOINT = lib.mkForce "https://${network.server}";
            AUTH_AUTHORITY = issuer;
            AUTH_CLIENT_ID = clientId;
            AUTH_AUDIENCE = clientId;
            AUTH_SUPPORTED_SCOPES = scopes;
            AUTH_REDIRECT_URI = "/auth";
            AUTH_SILENT_REDIRECT_URI = "/silent-auth";
          };
        };
      };

      services.netbird.relay = {
        enable = true;
        authSecretFile = relaySecret;
        settings = {
          listen-address = relayAddress;
          exposed-address = relayUrl;
        };
      };

      services.caddy.virtualHosts.${network.server}.extraConfig = ''
        handle /signalexchange.SignalExchange/* {
          reverse_proxy h2c://127.0.0.1:${toString cfg.signal.port}
        }
        handle /management.ManagementService/* {
          reverse_proxy h2c://127.0.0.1:${toString cfg.management.port}
        }
        handle /relay* {
          reverse_proxy ${relayAddress}
        }
      '';

      services.caddy.virtualHosts."http://:${toString dashboardPort}" = {
        listenAddresses = [ "127.0.0.1" ];
        extraConfig = ''
            handle /api/* {
              reverse_proxy 127.0.0.1:${toString cfg.management.port}
            }
            handle {
            root * ${cfg.dashboard.finalDrv}
            try_files {path} {path}.html {path}/
            file_server
          }
          # The dashboard's 404 page boots the app, which handles the OIDC
          # callback routes.
          handle_errors 404 {
            root * ${cfg.dashboard.finalDrv}
            rewrite * /404.html
            file_server
          }
        '';
      };

      # Members of this group may join the network.
      my.pocket-id.groups.netbird.friendlyName = "NetBird";
      my.pocket-id.clients.netbird = {
        id = clientId;
        name = "NetBird";
        public = true;
        callbackUrls = cliRedirects ++ [
          "${dashboardUrl}/auth"
          "${dashboardUrl}/silent-auth"
        ];
        logoutCallbackUrls = [ "${dashboardUrl}/" ];
        groups = [ "netbird" ];
      };

      my.tailnet-services.services = [
        {
          name = lib.head (lib.splitString "." network.dashboard);
          routes."/" = "http://127.0.0.1:${toString dashboardPort}";
        }
      ];
    };
}
