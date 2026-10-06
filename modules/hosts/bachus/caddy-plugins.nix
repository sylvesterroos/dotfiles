# Caddy built with the Porkbun DNS provider so certificates can be issued
# through DNS-01, which works for names that resolve to a tailnet address.
#
# withPlugins recompiles Caddy from source with xcaddy. The hash below is the
# fixed-output hash of that build; Nix rejects the build if the plugin set ever
# changes, which is the intended guard.
{
  flake.modules.nixos.bachus =
    { config, pkgs, ... }:
    {
      services.caddy.package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/porkbun@v0.3.1" ];
        hash = "sha256-iFuoa6k2r3jUPazHHujhB4bBq3Fz0Mv0Tjsr+gxMYQQ=";
      };

      # The Porkbun credentials used by the DNS-01 challenge.
      services.caddy.environmentFile = config.sops.templates."porkbun.env".path;

      sops.templates."porkbun.env" = {
        content = ''
          PORKBUN_API_TOKEN=${config.sops.placeholder.porkbun_api_key}
          PORKBUN_SECRET_API_KEY=${config.sops.placeholder.porkbun_secret_api_key}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
}
