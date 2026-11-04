{ config, ... }:
let
  inherit (config) tailnetDomain;
in
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.oidc-gate;
      redirectUrl = name: "https://${name}.${tailnetDomain}/oauth2/callback";
    in
    {
      options.my.oidc-gate.apps = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              upstreamPort = lib.mkOption {
                type = lib.types.port;
                description = "Loopback port of the application the gate forwards signed-in requests to.";
              };
              port = lib.mkOption {
                type = lib.types.port;
                description = "Loopback port the gate listens on; its tailnet service routes here.";
              };
              openRoutes = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Path regexes the gate forwards without sign-in; the application itself must authenticate them.";
              };
            };
          }
        );
        default = { };
        description = ''
          Applications that sign users in through Pocket ID by way of an
          oauth2-proxy gate, keyed by tailnet service name. Members of the
          Pocket ID group `gate` pass.
        '';
      };

      config = lib.mkIf (cfg.apps != { }) {
        my.tailnet-services.services = lib.mapAttrsToList (name: app: {
          inherit name;
          routes."/" = "http://127.0.0.1:${toString app.port}";
        }) cfg.apps;

        sops.secrets =
          let
            restartUnits = map (name: "oidc-gate-${name}.service") (lib.attrNames cfg.apps);
          in
          {
            "gate/oidc_client_secret".restartUnits = restartUnits;
            "gate/cookie_secret".restartUnits = restartUnits;
          };

        my.pocket-id.groups.gate.friendlyName = "Gated applications";
        my.pocket-id.clients.gate = {
          id = "gate";
          name = "Gated applications";
          callbackUrls = map redirectUrl (lib.attrNames cfg.apps);
          groups = [ "gate" ];
          secret = "gate/oidc_client_secret";
        };

        systemd.services = lib.mapAttrs' (
          name: app:
          lib.nameValuePair "oidc-gate-${name}" {
            description = "Pocket ID sign-in in front of ${name}";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network-online.target"
              "caddy.service"
              "pocket-id.service"
            ];
            wants = [ "network-online.target" ];
            script = ''
              exec ${lib.getExe pkgs.oauth2-proxy} \
                ${
                  lib.escapeShellArgs (
                    [
                      "--provider=oidc"
                      "--oidc-issuer-url=${config.services.pocket-id.settings.APP_URL}"
                      "--client-id=gate"
                      "--redirect-url=${redirectUrl name}"
                      "--scope=openid email profile"
                      "--code-challenge-method=S256"
                      "--email-domain=*"
                      "--insecure-oidc-allow-unverified-email=true"
                      "--skip-provider-button=true"
                      "--reverse-proxy=true"
                      "--cookie-secure=true"
                      "--http-address=127.0.0.1:${toString app.port}"
                      "--upstream=http://127.0.0.1:${toString app.upstreamPort}"
                    ]
                    ++ map (route: "--skip-auth-route=${route}") app.openRoutes
                  )
                } \
                --client-secret-file "$CREDENTIALS_DIRECTORY/client-secret" \
                --cookie-secret-file "$CREDENTIALS_DIRECTORY/cookie-secret"
            '';
            serviceConfig = {
              DynamicUser = true;
              LoadCredential = [
                "client-secret:${config.sops.secrets."gate/oidc_client_secret".path}"
                "cookie-secret:${config.sops.secrets."gate/cookie_secret".path}"
              ];
              Restart = "on-failure";
              RestartSec = 5;
            };
          }
        ) cfg.apps;
      };
    };
}
