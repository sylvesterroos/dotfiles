{
  config,
  ...
}:
let
  atticShared = import ../../modules/shared/attic.nix { };
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
      name = "plausible";
      target = "127.0.0.1:${toString config.services.plausible.server.port}";
    }
  ];
}
