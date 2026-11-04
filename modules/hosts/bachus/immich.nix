{ config, ... }:
let
  mv = config.multiverse;
  inherit (config) serviceFrom tailnetDomain;
  origin = "https://immich.${tailnetDomain}";
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
        machine-learning.enable = false;
        settings = {
          nightlyTasks.startTime = "21:00";
          machineLearning.urls = [ "http://100.91.77.3:3003" ];
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
