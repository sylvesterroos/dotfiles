{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      # One-time prerequisites outside Nix (Tailscale admin console):
      #   1. Tag bachus (e.g. tag:server) — service hosts must be tagged nodes.
      #   2. Define every service below on the Services page (name + tcp:443).
      #   3. Add a services auto-approver rule so bachus can advertise them.
      # After that, each entry is reachable at https://<name>.allosaurus-snapper.ts.net
      my.tailnet-services.services = [
        {
          name = "jellyfin";
          target = "http://127.0.0.1:8096";
          headscale = true;
        }
        {
          name = "audiobookshelf";
          target = "http://127.0.0.1:${toString config.services.audiobookshelf.port}";
        }
        {
          name = "immich";
          target = "http://127.0.0.1:${toString config.services.immich.port}";
        }
        {
          name = "home-assistant";
          target = "http://127.0.0.1:8123";
        }
        {
          name = "open-webui";
          target = "http://127.0.0.1:${toString config.services.open-webui.port}";
        }
        {
          name = "radarr";
          target = "http://127.0.0.1:7878";
        }
        {
          name = "sonarr";
          target = "http://127.0.0.1:8989";
        }
        {
          name = "prowlarr";
          target = "http://127.0.0.1:9696";
        }
        {
          name = "qbittorrent";
          target = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
        }
        {
          name = "qui";
          target = "http://127.0.0.1:7476";
        }
        {
          name = "files";
          target = "http://127.0.0.1:3923";
        }
        {
          name = "syncthing";
          target = "http://127.0.0.1:8384";
        }
        {
          # Hermes memory API for every device on the tailnet.
          name = "hindsight";
          target = "http://127.0.0.1:8888";
        }
        {
          name = "headplane";
          target = "http://127.0.0.1:${toString config.services.headplane.settings.server.port}";
        }
        {
          name = "playkeeper";
          # The panel speaks only TLS, with its own self-signed certificate.
          target = "https+insecure://127.0.0.1:8444";
        }
      ];

      # Hermes on https://bachus.allosaurus-snapper.ts.net. The ports follow the
      # hermes-relay plugin's convention, so `hermes pair` detects the TLS
      # listeners itself and advertises https/wss to the app.
      my.tailnet-services.listeners = [
        {
          port = 10443;
          target = "http://127.0.0.1:9119"; # dashboard + relay transport
        }
        {
          port = 8642;
          target = "http://127.0.0.1:8642"; # API server
        }
        {
          port = 9119;
          target = "http://127.0.0.1:9119"; # dashboard + relay transport
        }
      ];
    };
}
