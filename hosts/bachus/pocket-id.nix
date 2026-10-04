{ config, ... }: {
  sops.secrets."pocket-id/encryption_key" = { };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://pocket-id.sylvesterroos.com";
      PORT = 1411;
      TRUST_PROXY = true;
      ANALYTICS_DISABLED = true;
    };
    credentials.ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption_key".path;
  };

  services.caddy.virtualHosts."pocket-id.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.pocket-id.settings.PORT}
    '';
  };
}
