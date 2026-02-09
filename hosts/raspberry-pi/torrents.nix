{
  config,
  lib,
  ...
}:
let
  ports = {
    httpProxy = 8888;
    shadowsocks = 8388;
    prowlarr = 9696;
    radarr = 7878;
    sonarr = 8989;
    flaresolverr = 8191;
    qbittorrent = 8085;
  };

  mkPort =
    hostPort: containerPort: protocol:
    "${toString hostPort}:${toString containerPort}${
      lib.optionalString (protocol != null) "/${protocol}"
    }";
  mkPortTcp = hostPort: containerPort: mkPort hostPort containerPort "tcp";
  mkPortUdp = hostPort: containerPort: mkPort hostPort containerPort "udp";
  mkPortAny = hostPort: containerPort: mkPort hostPort containerPort null;
in
{
  virtualisation.oci-containers = lib.mkIf config.my.podman.enable {
    containers = {
      gluetun = {
        image = "qmcgaw/gluetun";
        ports = [
          (mkPortTcp ports.httpProxy ports.httpProxy)
          (mkPortTcp ports.shadowsocks ports.shadowsocks)
          (mkPortUdp ports.shadowsocks ports.shadowsocks)
          (mkPortAny ports.prowlarr ports.prowlarr)
          (mkPortAny ports.radarr ports.radarr)
          (mkPortAny ports.sonarr ports.sonarr)
          (mkPortAny ports.qbittorrent ports.qbittorrent)
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
        dependsOn = [ "gluetun" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Amsterdam";
        };
        volumes = [
          "prowlarr:/config"
        ];
        extraOptions = [ "--network=container:gluetun" ];
      };

      flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        ports = [ (mkPortAny ports.flaresolverr ports.flaresolverr) ];
        environment = {
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          CAPTCHA_SOLVER = "none";
          TZ = "Europe/Amsterdam";
        };
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        dependsOn = [ "gluetun" ];
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
        extraOptions = [ "--network=container:gluetun" ];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        dependsOn = [ "gluetun" ];
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
        extraOptions = [ "--network=container:gluetun" ];
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        dependsOn = [ "gluetun" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Amsterdam";
          WEBUI_PORT = toString ports.qbittorrent;
          DOCKER_MODS = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
        };
        volumes = [
          "qbittorrent:/config"
          "/srv/downloads:/downloads"
        ];
        extraOptions = [ "--network=container:gluetun" ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/downloads 2775 sylvester users -"
  ];

  networking.firewall.allowedTCPPorts = [
    ports.httpProxy
    ports.shadowsocks
    ports.prowlarr
    ports.radarr
    ports.sonarr
    ports.flaresolverr
    ports.qbittorrent
  ];

  networking.firewall.allowedUDPPorts = [
    ports.shadowsocks
  ];
}
