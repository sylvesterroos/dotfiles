{ config, ... }:
{
  services.open-design = {
    enable = true;
    autoStart = true;
    webFrontend = {
      enable = true;
      allowedOrigins = [ "https://open-design.sylvesterroos.com" ];
    };
  };

  services.caddy.virtualHosts."open-design.sylvesterroos.com".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.open-design.webFrontend.port}
  '';
}
