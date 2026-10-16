{
  flake.modules.nixos.bachus =
    { config, ... }:
    {
      services.audiobookshelf = {
        enable = true;
        # Reached via https://audiobookshelf.<tailnet>.ts.net (see tailnet-services.nix).
        host = "127.0.0.1";
        port = 8000;
        # Share the media group so it can read /srv/media/books.
        # Literal on purpose: the module defines users.groups from this value,
        # so reading config.users.groups here recurses infinitely.
        group = "media";
      };

      systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = "/srv";

      systemd.tmpfiles.rules =
        let
          sylvester = config.users.users.sylvester.name;
          media = config.users.groups.media.name;
        in
        [
          "d /srv/media/books/public 2775 ${sylvester} ${media} -"
          "d /srv/media/books/private 2775 ${sylvester} ${media} -"

          "d /srv/media/podcasts 2775 ${sylvester} ${media} -"
        ];
    };
}
