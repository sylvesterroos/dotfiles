# Keep torrent-service DNS inside Proton without changing host DNS.
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      users = [
        "qbittorrent"
        "prowlarr"
        "radarr"
        "sonarr"
        "flaresolverr"
      ];
      resolver = pkgs.writeText "proton-resolv.conf" ''
        nameserver 10.2.0.1
        nameserver 2a07:b944::2:1
        options timeout:2 attempts:2
      '';
      # nss-resolve and the host's nsncd would resolve outside the caller's
      # UID-based VPN routing. Keep other NSS databases unchanged.
      nsswitch = pkgs.writeText "proton-nsswitch.conf" (
        lib.concatMapStringsSep "\n" (
          line: if lib.hasPrefix "hosts:" line then "hosts: files dns" else line
        ) (lib.splitString "\n" config.environment.etc."nsswitch.conf".text)
      );
    in
    {
      systemd.services = lib.genAttrs users (_: {
        serviceConfig = {
          BindReadOnlyPaths = [
            "${resolver}:/etc/resolv.conf"
            "${nsswitch}:/etc/nsswitch.conf"
          ];
          InaccessiblePaths = [ "-/run/nscd" ];
        };
      });
    };
}
