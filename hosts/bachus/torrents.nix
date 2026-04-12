{
  config,
  pkgs,
  ...
}:
let
  vpnTable = 1000;
  qbUser = config.users.users.qbittorrent.name;
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
    dns = [ "10.2.0.1" ];
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
      ip rule add uidrange $(id -u ${qbUser})-$(id -u ${qbUser}) table ${toString vpnTable} priority 30001
      ip rule add uidrange $(id -u ${qbUser})-$(id -u ${qbUser}) table main suppress_prefixlength 0 priority 30000
      ip -6 route add unreachable default table ${toString vpnTable}
    '';

    preDown = ''
      ip -6 route del unreachable default table ${toString vpnTable} || true
      ip rule del uidrange $(id -u ${qbUser})-$(id -u ${qbUser}) table ${toString vpnTable} priority 30001 || true
      ip rule del uidrange $(id -u ${qbUser})-$(id -u ${qbUser}) table main suppress_prefixlength 0 priority 30000 || true
      ip route del default dev wg0 table ${toString vpnTable} || true
    '';
  };

  services = {
    prowlarr = {
      enable = true;
      openFirewall = true;
    };

    flaresolverr = {
      enable = true;
      openFirewall = true;
    };

    radarr = {
      enable = true;
      openFirewall = true;
    };

    sonarr = {
      enable = true;
      openFirewall = true;
    };

    qbittorrent = {
      enable = true;
      webuiPort = 8085;
      openFirewall = true;
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

  systemd.tmpfiles.rules =
    let
      qbittorrent = config.users.users.qbittorrent.name;
      media = config.users.groups.media.name;
    in
    [
      "d /srv/downloads 2775 ${qbittorrent} ${media} -"
    ];
}
