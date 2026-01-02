{config, ...}: {
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
    # in order to avoid having ADMIN_TOKEN in the nix store it can be also set with the help of an environment file
    environmentFile = config.sops.secrets."vaultwarden/vaultwarden.env".path;
    config = {
      # Refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      DOMAIN = "https://vw.sylvesterroos.com";
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;

      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;

      # If you use an external mail server, follow:
      #   https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
      # SMTP_HOST = "127.0.0.1";
      # SMTP_FROM = "admin@vw.sylvesterroos.com";
      # SMTP_FROM_NAME = "sylvesterroos.com Vaultwarden server";
    };
  };

  services.caddy.virtualHosts."vw.sylvesterroos.com".extraConfig = ''
    encode zstd gzip

    reverse_proxy :${toString config.services.vaultwarden.config.ROCKET_PORT} {
        header_up X-Real-IP {remote_host}
    }
  '';
}
