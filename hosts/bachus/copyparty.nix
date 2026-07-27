{
  config,
  ...
}:
{
  services.copyparty = {
    enable = true;

    settings = {
      # Listen on localhost only — Caddy reverse-proxies from :80/:443
      i = "127.0.0.1";
      # Respect X-Forwarded-For header from Caddy
      xff-src = "127.0.0.0/8";
      # Enable upload database for unpost, dedup
      e2d = true;
      # Enable audio metadata indexing
      e2ts = true;
      # Enable file hashing for dedup
      e2dsa = true;
    };

    volumes = {
      "/" = {
        path = "/srv/media";
        access = {
          r = "*";
        };
        flags = {
          grid = true;
        };
      };
    };
  };

  # Reverse proxy via Caddy
  services.caddy.virtualHosts."files.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };

  # Ensure copyparty service waits for /srv mount
  systemd.services.copyparty.unitConfig.RequiresMountsFor = "/srv";
}
