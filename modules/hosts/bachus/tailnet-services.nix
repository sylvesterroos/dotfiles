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
          routes."/" = "http://127.0.0.1:8096";
          headscale = true;
        }
        {
          name = "audiobookshelf";
          routes."/" = "http://127.0.0.1:${toString config.services.audiobookshelf.port}";
        }
        {
          name = "immich";
          routes."/" = "http://127.0.0.1:${toString config.services.immich.port}";
        }
        {
          name = "home-assistant";
          routes."/" = "http://127.0.0.1:8123";
        }
        {
          name = "radarr";
          routes."/" = "http://127.0.0.1:7878";
        }
        {
          name = "sonarr";
          routes."/" = "http://127.0.0.1:8989";
        }
        {
          name = "prowlarr";
          routes."/" = "http://127.0.0.1:9696";
        }
        {
          name = "qbittorrent";
          routes."/" = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
        }
        {
          name = "qui";
          routes."/" = "http://127.0.0.1:7476";
        }
        {
          name = "files";
          routes."/" = "http://127.0.0.1:3923";
          headscale = true;
        }
        {
          name = "syncthing";
          routes."/" = "http://127.0.0.1:8384";
        }
        {
          # Hermes memory for every device on the tailnet: the control plane
          # UI at the root, the API under /memory (HINDSIGHT_API_BASE_PATH).
          name = "hindsight";
          routes = {
            "/" = "http://127.0.0.1:9999";
            "/memory" = "http://127.0.0.1:8888";
          };
        }
        {
          name = "headplane";
          routes."/" = "http://127.0.0.1:${toString config.services.headplane.settings.server.port}";
        }
        {
          name = "playkeeper";
          # The panel speaks only TLS, with its own self-signed certificate.
          routes."/" = "https+insecure://127.0.0.1:8444";
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
