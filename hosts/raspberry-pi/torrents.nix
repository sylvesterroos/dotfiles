{
  config,
  lib,
  ...
}: {
  virtualisation.oci-containers = lib.mkIf config.my.podman.enable {
    containers = {
      gluetun = {
        image = "qmcgaw/gluetun";
        ports = [
          "8888:8888/tcp" # HTTP proxy
          "8388:8388/tcp" # Shadowsocks
          "8388:8388/udp" # Shadowsocks
          "9696:9696" # prowlarr
          "9091:9091" # transmission
          "51413:51413"
          "51413:51413/udp"
          "7878:7878" # radarr
          "8989:8989" # sonarr
        ];
        volumes = [
          "gluetun:/gluetun"
        ];
        environment = {
          VPN_SERVICE_PROVIDER = "windscribe";
          VPN_TYPE = "wireguard";
          SERVER_REGIONS = "Netherlands";
          WIREGUARD_ADDRESSES = "100.112.161.64/32";
          WIREGUARD_ENDPOINT_PORT = "443";
          TZ = "Europe/Amsterdam";
          UPDATER_PERIOD = "24h";
        };
        environmentFiles = [
          config.sops.secrets."gluetun/env".path
        ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        dependsOn = ["gluetun"];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Amsterdam";
        };
        volumes = [
          "prowlarr:/config"
        ];
        extraOptions = ["--network=container:gluetun"];
      };

      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = ["8191:8191"];
        environment = {
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          CAPTCHA_SOLVER = "none";
          TZ = "Europe/Amsterdam";
        };
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        dependsOn = ["gluetun"];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Amsterdam";
        };
        volumes = [
          "radarr:/config"
          "/srv/media/movies:/movies"
          "/srv/downloads:/downloads"
        ];
        extraOptions = ["--network=container:gluetun"];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        dependsOn = ["gluetun"];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Amsterdam";
        };
        volumes = [
          "sonarr:/config"
          "/srv/media/series:/tv"
          "/srv/downloads:/downloads"
        ];
        extraOptions = ["--network=container:gluetun"];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/downloads 2775 sylvester users -"
  ];

}
