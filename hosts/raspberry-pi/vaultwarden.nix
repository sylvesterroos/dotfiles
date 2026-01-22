{
  config,
  lib,
  ...
}:
let
  PORT = 8222;
in
{
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
      ROCKET_PORT = PORT;

      # If you use an external mail server, follow:
      #   https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
      # SMTP_HOST = "127.0.0.1";
      # SMTP_FROM = "admin@vw.sylvesterroos.com";
      # SMTP_FROM_NAME = "sylvesterroos.com Vaultwarden server";

      EXTENDED_LOGGING = true;
    };
  };

  services.caddy.virtualHosts."vw.sylvesterroos.com".extraConfig = ''
    encode zstd gzip

    reverse_proxy :${toString PORT} {
        header_up X-Real-IP {remote_host}
    }
  '';

  services.fail2ban = {
    jails = {
      vaultwarden-web = {
        settings = {
          enabled = true;
          port = "80,443,${toString PORT}";
          banaction = "%(banaction_allports)s";
          backend = "systemd";
          filter = "vaultwarden[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
          maxretry = 3;
          bantime = 14400;
          findtime = 14400;
        };
      };

      vaultwarden-admin = {
        settings = {
          enabled = true;
          port = "80,443,${toString PORT}";
          banaction = "%(banaction_allports)s";
          backend = "systemd";
          filter = "vaultwarden-admin[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
          maxretry = 3;
          bantime = 14400;
          findtime = 14400;
        };
      };

      vaultwarden-totp = {
        settings = {
          enabled = true;
          port = "80,443,${toString PORT}";
          banaction = ''iptables-multiport[name=vaultwarden-totp, port="80,443,${toString PORT}", protocol=tcp]'';
          backend = "systemd";
          filter = "vaultwarden-totp[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
          maxretry = 3;
          bantime = 14400;
          findtime = 14400;
        };
      };
    };
  };

  environment.etc = {
    "fail2ban/filter.d/vaultwarden.local".text = lib.mkDefault (
      lib.mkAfter ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*?Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
        ignoreregex =
      ''
    );

    "fail2ban/filter.d/vaultwarden-admin.local".text = lib.mkDefault (
      lib.mkAfter ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*Invalid admin token\. IP: <ADDR>.*$
        ignoreregex =
      ''
    );

    "fail2ban/filter.d/vaultwarden-totp.local".text = lib.mkDefault (
      lib.mkAfter ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*\[ERROR\] Invalid TOTP code! Server time: (.*) UTC IP: <ADDR>$
        ignoreregex =
      ''
    );
  };
}
