{ ... }:
{
  services.caddy = {
    enable = true;
    email = "sylvester@sylvesterroos.com";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
