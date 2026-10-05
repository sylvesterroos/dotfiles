{
  config,
  ...
}:
let
  atticShared = import ../../legacy/shared/attic.nix { };
in
{
  # One-time prerequisites outside Nix (Tailscale admin console):
  #   1. Tag bachus (e.g. tag:server) — service hosts must be tagged nodes.
  #   2. Define every service below on the Services page (name + tcp:443).
  #   3. Add a services auto-approver rule so bachus can advertise them.
  # After that, each entry is reachable at https://<name>.allosaurus-snapper.ts.net
  my.tailnet-services.services = [
    {
      name = "jellyfin";
      target = "127.0.0.1:8096";
      headscale = true;
    }
    {
      name = "immich";
      target = "127.0.0.1:${toString config.services.immich.port}";
    }
    {
      name = "home-assistant";
      target = "127.0.0.1:8123";
    }
    {
      name = "open-webui";
      target = "127.0.0.1:${toString config.services.open-webui.port}";
    }
    {
      name = "radarr";
      target = "127.0.0.1:7878";
    }
    {
      name = "sonarr";
      target = "127.0.0.1:8989";
    }
    {
      name = "prowlarr";
      target = "127.0.0.1:9696";
    }
    {
      name = "qbittorrent";
      target = "127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
    }
    {
      name = "qui";
      target = "127.0.0.1:7476";
    }
    {
      name = "files";
      target = "127.0.0.1:3923";
    }
    {
      name = "attic";
      target = "127.0.0.1:${toString atticShared.port}";
    }
    {
      name = "syncthing";
      target = "127.0.0.1:8384";
    }
    {
      name = "headplane";
      target = "127.0.0.1:${toString config.services.headplane.settings.server.port}";
    }
  ];

  # Hermes on https://bachus.allosaurus-snapper.ts.net. The ports follow the
  # hermes-relay plugin's convention, so `hermes pair` detects the TLS
  # listeners itself and advertises https/wss to the app.
  my.tailnet-services.listeners = [
    {
      port = 10443;
      target = "127.0.0.1:9119"; # dashboard + relay transport
    }
    {
      port = 8642;
      target = "127.0.0.1:8642"; # API server
    }
    {
      port = 9119;
      target = "127.0.0.1:9119"; # dashboard + relay transport
    }
  ];
}
