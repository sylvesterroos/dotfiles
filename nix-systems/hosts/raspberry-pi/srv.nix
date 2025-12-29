{config, ...}: {
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
  systemd.tmpfiles.rules = let
    sylvester = config.users.users.sylvester.name;
  in [
    "d /srv/media 0755 ${sylvester} users -"

    "d /srv/media/movies/public 2775 ${sylvester} users -"
    "d /srv/media/movies/private 2775 ${sylvester} users -"

    "d /srv/media/series/public 2775 ${sylvester} users -"
    "d /srv/media/series/private 2775 ${sylvester} users -"

    "d /srv/media/music/public 2775 ${sylvester} users -"
    "d /srv/media/music/private 2775 ${sylvester} users -"
  ];
}
