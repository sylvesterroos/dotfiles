# Forwards localhost:8787 to the RimMolt MCP server on the Steam Deck. The
# Deck lives on the headscale tailnet, which local programs reach only through
# headscaled's HTTP proxy, so Hermes cannot dial it directly. socat opens a
# CONNECT tunnel through that proxy for each connection.
{ config, ... }:
let
  inherit (config.headscaleNetwork) domain;
in
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.my.headscaled) proxy;
      target = "steamdeck.${domain}";
      port = 8787;
    in
    {
      systemd.services.rimmolt-forward = {
        description = "Forward localhost:${toString port} to RimMolt on the Steam Deck";
        wantedBy = [ "multi-user.target" ];
        after = [ "headscaled.service" ];
        wants = [ "headscaled.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.socat} TCP-LISTEN:${toString port},bind=127.0.0.1,reuseaddr,fork PROXY:localhost:${target}:${toString port},proxyport=${lib.last (lib.splitString ":" proxy)}";
          Restart = "always";
          RestartSec = 5;
          DynamicUser = true;
        };
      };
    };
}
