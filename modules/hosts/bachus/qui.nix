{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      services.qui = {
        enable = true;

        # Bind to all interfaces so qui is reachable over Tailscale.
        settings.host = "0.0.0.0";

        # Session secret, generated with `openssl rand -hex 32`. Also used to
        # encrypt stored instance passwords: keep it stable or saved qBittorrent
        # credentials stop decrypting.
        secretFile = config.sops.secrets."qui/session_secret".path;
      };

      systemd.services.qui = {
        after = [ "qbittorrent.service" ];
        wants = [ "qbittorrent.service" ];
      };

      sops.secrets."qui/session_secret" = { };
    };
}
