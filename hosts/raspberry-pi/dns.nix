# TODO: remove this once we get a router that supports hairpin NAT
{ config, lib, ... }:
let
  lanIP = "192.168.1.235";

  caddyHosts = config.services.caddy.virtualHosts;
  localDomains = lib.attrNames caddyHosts;

  domainAddresses = map (domain: "/${domain}/${lanIP}") localDomains;
in
{
  services.dnsmasq = {
    enable = true;
    settings = {
      server = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      address = domainAddresses;
      no-resolv = true;
      cache-size = 1000;
      # Only listen on specific interfaces, not podman networks
      interface = [
        "end0" # Main ethernet interface
        "wlan0" # WiFi interface
        "tailscale0" # Tailscale interface
      ];
      bind-dynamic = true; # Bind to interfaces even if they're down
    };
  };

  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
}
