{ config, ... }:
let
  network = config.headscaleNetwork;
in
{
  flake.modules.nixos.bachus =
    { config, ... }:
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
          # Dedicated allocation for the second network on desktop hosts.
          prefixes = {
            v4 = network.ipv4Prefix;
            v6 = network.ipv6Prefix;
          };
          dns = {
            magic_dns = true;
            base_domain = network.domain;
            override_local_dns = false;
            # Seeded at boot and rewritten by headscaled-publish once bachus has
            # an address on the headscale tailnet.
            extra_records_path = "/var/lib/headscale/extra-records.json";
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
    };
}
