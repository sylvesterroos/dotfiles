{ config, pkgs, ... }:
{
  services.open-webui = {
    enable = true;
    package = pkgs.unstable.open-webui;
    port = 3000;
    host = "127.0.0.1";
    openFirewall = false;
  };

  services.caddy.virtualHosts."chat.sylvesterroos.com".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.open-webui.port}
  '';
}
