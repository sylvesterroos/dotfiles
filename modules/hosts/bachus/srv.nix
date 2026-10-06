{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      users.groups.media = {
        gid = 990;
        members = with config.users.users; [
          sylvester.name
          jellyfin.name
          qbittorrent.name
          radarr.name
          sonarr.name
        ];
      };

      # string with six fields separated by whitespace:
      #   <type> <path> <mode> <owner> <group> <age>
      #
      # Fields:
      #   type   - one-letter action
      #   path   - absolute path to operate on.
      #   mode   - octal permissions (e.g. 0755). Use "-" to leave unchanged/not used.
      #   owner  - username or UID to own the file/dir. Use "-" to leave unchanged.
      #   group  - group name or GID. Use "-" to leave unchanged.
      #   age    - retention/cleanup age for cleaning rules (e.g. 10d), or "-" when not applicable.
      systemd.tmpfiles.rules =
        let
          sylvester = config.users.users.sylvester.name;
          media = config.users.groups.media.name;
        in
        [
          "d /srv/media 0775 ${sylvester} ${media} -"

          "d /srv/media/movies/public 2775 ${sylvester} ${media} -"
          "d /srv/media/movies/private 2775 ${sylvester} ${media} -"

          "d /srv/media/series/public 2775 ${sylvester} ${media} -"
          "d /srv/media/series/private 2775 ${sylvester} ${media} -"

          "d /srv/media/music/public 2775 ${sylvester} ${media} -"
          "d /srv/media/music/private 2775 ${sylvester} ${media} -"

          "d /srv/media/books/public 2775 ${sylvester} ${media} -"
          "d /srv/media/books/private 2775 ${sylvester} ${media} -"

          "d /srv/media/immich 0750 immich immich -"
        ];

      systemd.services.immich-server.unitConfig.RequiresMountsFor = "/srv /srv/media/immich";
      systemd.services.jellyfin.unitConfig.RequiresMountsFor = "/srv";
      systemd.services.qbittorrent.unitConfig.RequiresMountsFor = "/srv";
      systemd.services.radarr.unitConfig.RequiresMountsFor = "/srv";
      systemd.services.sonarr.unitConfig.RequiresMountsFor = "/srv";
    };
}
