{ config, lib, ... }:
with lib;
let
  # bachus's tailscale IP (do not bind 0.0.0.0)
  tailscaleIp = "100.95.166.12";
in
{
  # JWT signing secret for attic tokens, decrypted from sops (never in the nix store)
  sops.secrets."atticd/rs256_secret" = { };

  sops.templates."atticd.env" = {
    content = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."atticd/rs256_secret"}
    '';
  };

  services.atticd = {
    enable = true;
    environmentFile = config.sops.templates."atticd.env".path;
    settings = {
      listen = "${tailscaleIp}:8080";
      jwt = { };
      garbage-collection = {
        interval = "12h";
        default-retention-period = "30d";
      };
    };
  };

  # atticd binds only the tailscale IP; allow port 8080 on tailscale0 exclusively
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];
}
