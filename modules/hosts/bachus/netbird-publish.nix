# Publishes the services flagged `netbird` (tailnet-services.nix) on the
# NetBird network as <name>.<NetBird domain>. Bachus's client registers each
# name as an extra DNS label, so it resolves to bachus's NetBird address.
# Caddy answers those names on its public listener for NetBird addresses only.
{ config, ... }:
let
  network = config.netbirdNetwork;
in
{
  flake.modules.nixos.bachus =
    { config, lib, ... }:
    let
      services = lib.filter (s: s.netbird) config.my.tailnet-services.services;

      # Same mount semantics as tailscale serve: the path prefix is stripped
      # before proxying.
      route =
        path: upstream:
        if path == "/" then
          "handle {\n  reverse_proxy ${upstream}\n}"
        else
          "handle_path ${lib.removeSuffix "/" path}/* {\n  reverse_proxy ${upstream}\n}";
    in
    {
      services.netbird.clients.netbird.environment.NB_EXTRA_DNS_LABELS = lib.concatMapStringsSep "," (
        s: s.name
      ) services;

      # Certificates come through DNS-01 (Porkbun): the names resolve to a
      # NetBird address, which HTTP-01 cannot reach.
      services.caddy.virtualHosts = lib.listToAttrs (
        map (
          s:
          lib.nameValuePair "${s.name}.${network.domain}" {
            extraConfig = ''
              tls {
                dns porkbun {
                  api_key {env.PORKBUN_API_TOKEN}
                  api_secret_key {env.PORKBUN_SECRET_API_KEY}
                }
              }

              @outside not remote_ip ${network.range}
              # `route` keeps the written order; Caddy otherwise sorts `handle`
              # before `abort`, and the proxy answers first.
              route {
                abort @outside
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList route s.routes)}
              }
            '';
          }
        ) services
      );
    };
}
