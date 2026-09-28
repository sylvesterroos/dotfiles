{
  config,
  lib,
  pkgs,
  ...
}:
let
  vpnTable = 1000;
  vpnUsers = map (u: config.users.users.${u}.name) [
    "qbittorrent"
    "prowlarr"
    "radarr"
    "sonarr"
  ];
  ruleForUser = user: ''
    ip rule add uidrange $(id -u ${user})-$(id -u ${user}) table ${toString vpnTable} priority 30001
    ip rule add uidrange $(id -u ${user})-$(id -u ${user}) table main suppress_prefixlength 0 priority 30000
  '';
  delRuleForUser = user: ''
    ip rule del uidrange $(id -u ${user})-$(id -u ${user}) table ${toString vpnTable} priority 30001 || true
    ip rule del uidrange $(id -u ${user})-$(id -u ${user}) table main suppress_prefixlength 0 priority 30000 || true
  '';
in
{
  assertions = [
    {
      assertion = config.services.qbittorrent.enable -> config.networking.wg-quick.interfaces ? wg0;
      message = "qbittorrent requires the wg0 WireGuard interface to be configured.";
    }
  ];

  networking.firewall.checkReversePath = "loose";

  networking.wg-quick.interfaces.wg0 = {
    privateKeyFile = config.sops.secrets."wireguard/protonvpn_nl/private_key".path;
    address = [ "10.2.0.2/32" ];
    table = "off";

    peers = [
      {
        publicKey = "lK9RKsf9y5/jehblqhoSGV7FtlErG7QqLy13G3IV2Ao=";
        allowedIPs = [
          "0.0.0.0/0"
        ];
        endpoint = "46.29.25.5:51820";
        persistentKeepalive = 25;
      }
    ];

    postUp = ''
      ip route add default dev wg0 table ${toString vpnTable}
      # Last-resort kill switch: if wg0 disappears without preDown running,
      # the uid rules still steer traffic into this table, and the
      # unreachable default makes it die instead of falling through to the
      # clearnet route in main.
      ip route add unreachable default table ${toString vpnTable} metric 2048
      ${builtins.concatStringsSep "" (map ruleForUser vpnUsers)}
      ip -6 route add unreachable default table ${toString vpnTable}
    '';

    preDown = ''
      ip -6 route del unreachable default table ${toString vpnTable} || true
      ${builtins.concatStringsSep "" (map delRuleForUser vpnUsers)}
      ip route del unreachable default table ${toString vpnTable} metric 2048 || true
      ip route del default dev wg0 table ${toString vpnTable} || true
    '';
  };

  services = {
    prowlarr = {
      enable = true;
    };

    flaresolverr = {
      enable = true;
    };

    radarr = {
      enable = true;
    };

    sonarr = {
      enable = true;
    };

    qbittorrent = {
      enable = true;
      webuiPort = 8085;
      # Tailnet-only via tailnet-services.nix: no openFirewall, web UI and
      # tracker traffic stay separated (UI via tailscale serve, torrent
      # traffic via wg0).
      serverConfig = {
        BitTorrent = {
          Session = {
            DefaultSavePath = "/srv/downloads";
            GlobalMaxSeedingMinutes = 10000;
            ShareLimitAction = "Stop";
          };
        };
        Preferences = {
          LegalNotice.Accepted = true;
          WebUI = {
            AlternativeUIEnabled = true;
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
            Username = "sylvester";
            Password_PBKDF2 = "@ByteArray(SHulZq5Q8ROK0j5lDSRv5g==:lN1jwNif0jvZr5sc9rowJaU7n+l5K3OqK7D8A2Ij/RXC0jjj04YXtZp+oPoyYoxZ4hBa2xbE4q7DniDHJ9YHYQ==)";
          };
        };
      };
    };
  };

  systemd.services.qbittorrent = {
    after = [ "wg-quick-wg0.service" ];
    requires = [ "wg-quick-wg0.service" ];
    # UMask 0002 gives files 664 and dirs 775, allowing the media group
    # write access so sonarr/radarr can hardlink downloaded files.
    serviceConfig.UMask = "0002";
  };

  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    home = "/var/lib/prowlarr";
  };
  users.groups.prowlarr = { };

  systemd.services.prowlarr = {
    after = [ "wg-quick-wg0.service" ];
    requires = [ "wg-quick-wg0.service" ];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "prowlarr";
      Group = "prowlarr";
    };
  };

  systemd.services.radarr = {
    after = [ "wg-quick-wg0.service" ];
    requires = [ "wg-quick-wg0.service" ];
  };

  systemd.services.sonarr = {
    after = [ "wg-quick-wg0.service" ];
    requires = [ "wg-quick-wg0.service" ];
  };

  systemd.tmpfiles.rules =
    let
      qbittorrent = config.users.users.qbittorrent.name;
      media = config.users.groups.media.name;
    in
    [
      "d /srv/downloads 2775 ${qbittorrent} ${media} -"
    ];
}
