{ config, ... }: {
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
    };
  };

  services.caddy.virtualHosts."headscale.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.headscale.port}
    '';
  };
}
