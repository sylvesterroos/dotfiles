{ config, ... }: {
  sops.secrets."headplane/cookie_secret" = { };

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 9090;
        cookie_secret_path = config.sops.secrets."headplane/cookie_secret".path;
      };
    };
  };

  services.caddy.virtualHosts."headplane.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.headplane.settings.server.port}
    '';
  };
}
