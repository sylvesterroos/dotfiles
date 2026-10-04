{
  config,
  ...
}:
{
  sops.secrets."headscale/oidc_client_secret" = {
    owner = "headscale";
    group = "headscale";
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8090;
    settings = {
      server_url = "https://headscale.sylvesterroos.com";
      dns = {
        magic_dns = true;
        base_domain = "tailnet.sylvesterroos.com";
        override_local_dns = false;
      };
      oidc = {
        issuer = config.services.pocket-id.settings.APP_URL;
        client_id = "a9372b78-a6c9-43a2-96d9-aed19f285efb";
        client_secret_path = config.sops.secrets."headscale/oidc_client_secret".path;
        pkce.enabled = true;
      };
    };
  };

  services.caddy.virtualHosts."headscale.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.headscale.port}
    '';
  };
}
