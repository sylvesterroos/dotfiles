{ ... }:
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.caddy.virtualHosts."jf.sylvesterroos.com".extraConfig = ''
    reverse_proxy 127.0.0.1:8096
  '';
}
