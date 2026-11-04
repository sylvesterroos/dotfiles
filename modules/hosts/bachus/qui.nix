{ config, ... }:
let
  inherit (config) tailnetDomain;
in
{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      services.qui = {
        enable = true;

        settings = {
          host = "127.0.0.1";
          oidcEnabled = true;
          oidcIssuer = config.services.pocket-id.settings.APP_URL;
          oidcClientId = "qui";
          oidcRedirectUrl = "https://qui.${tailnetDomain}/api/auth/oidc/callback";
        };

        # Session secret, generated with `openssl rand -hex 32`. Also used to
        # encrypt stored instance passwords: keep it stable or saved qBittorrent
        # credentials stop decrypting.
        secretFile = config.sops.secrets."qui/session_secret".path;
      };

      systemd.services.qui = {
        after = [ "qbittorrent.service" ];
        wants = [ "qbittorrent.service" ];
        environment.QUI__OIDC_CLIENT_SECRET_FILE = config.sops.secrets."qui/oidc_client_secret".path;
      };

      sops.secrets."qui/session_secret" = { };
      sops.secrets."qui/oidc_client_secret" = {
        owner = config.services.qui.user;
        restartUnits = [ "qui.service" ];
      };

      my.pocket-id.groups.qui.friendlyName = "qui";
      my.pocket-id.clients.qui = {
        id = "qui";
        name = "qui";
        callbackUrls = [ config.services.qui.settings.oidcRedirectUrl ];
        groups = [ "qui" ];
        secret = "qui/oidc_client_secret";
      };
    };
}
