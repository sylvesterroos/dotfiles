{ config, ... }:
let
  mv = config.multiverse;
  inherit (config) serviceFrom tailnetDomain;
  origin = "https://immich.${tailnetDomain}";
  deltaMachineLearning = "100.91.77.3:3003";
  localMachineLearning = "127.0.0.1:3003";
  machineLearningRouter = "127.0.0.1:3004";
in
{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      imports = [
        (serviceFrom {
          pkgs = mv.tip;
          name = "immich";
          module = "services/web-apps/immich.nix";
        })
      ];

      services.immich = {
        enable = true;
        mediaLocation = "/srv/media/immich";
        host = "0.0.0.0";
        environment = {
          IMMICH_LOG_LEVEL = "verbose";
        };
        database.port = 5431;
        machine-learning.enable = true;
        settings = {
          nightlyTasks.startTime = "21:00";
          machineLearning.urls = [ "http://${machineLearningRouter}" ];
          oauth = {
            enabled = true;
            issuerUrl = config.services.pocket-id.settings.APP_URL;
            clientId = "immich";
            clientSecret._secret = config.sops.secrets."immich/oidc_client_secret".path;
            scope = "openid email profile";
            buttonText = "Sign in with Pocket ID";
          };
        };
      };

      # Text encoding for search runs on delta or, when delta is down, on the local CPU instance.
      # Every other model task runs on delta only. The router matches "textual" in the multipart
      # `entries` field, which Immich sends first, so it sits inside the buffered request start.
      services.haproxy = {
        enable = true;
        config = ''
          global
              maxconn 64

          defaults
              mode http
              timeout connect 3s
              timeout client 300s
              timeout server 300s
              option http-buffer-request

          frontend machine_learning
              bind ${machineLearningRouter}
              acl text_encoding req.body -m sub "\"textual\""
              use_backend text_encoding if text_encoding
              default_backend delta_only

          backend delta_only
              option httpchk GET /ping
              server delta ${deltaMachineLearning} check inter 5s fall 2 rise 1

          backend text_encoding
              option httpchk GET /ping
              server delta ${deltaMachineLearning} check inter 5s fall 2 rise 1
              server local ${localMachineLearning} check inter 5s backup
        '';
      };

      sops.secrets."immich/oidc_client_secret".restartUnits = [ "immich-server.service" ];

      my.pocket-id.groups.immich.friendlyName = "Immich";
      my.pocket-id.clients.immich = {
        id = "immich";
        name = "Immich";
        callbackUrls = [
          "${origin}/auth/login"
          "${origin}/user-settings"
          "app.immich:///oauth-callback"
        ];
        groups = [ "immich" ];
        secret = "immich/oidc_client_secret";
      };
      # Tailnet-only via tailnet-services.nix; the port stays firewalled.
    };
}
