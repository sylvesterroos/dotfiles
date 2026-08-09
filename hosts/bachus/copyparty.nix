{
  config,
  ...
}:
let
  # copyparty runs as its own user, so new files would be copyparty:copyparty
  # and unmanageable from the command line. These volume flags chown uploads to
  # a group the user belongs to and make them group-writable (the gid flag only
  # works for groups copyparty is a member of; see extraGroups below).
  homeFlags = {
    grid = true;
    chmod_f = toString 664;
    chmod_d = toString 775;
    gid = toString config.users.groups.users.gid;
  };
  # /srv/media uploads get the media group so jellyfin and the *arr stack can
  # keep reading them.
  mediaFlags = homeFlags // {
    gid = toString config.users.groups.media.gid;
  };
in
{
  services.copyparty = {
    enable = true;

    settings = {
      # Listen on localhost only — Caddy reverse-proxies from :80/:443
      i = "127.0.0.1";
      # Respect X-Forwarded-For header from Caddy
      xff-src = "127.0.0.0/8";
      # Tell copyparty it's behind a reverse proxy;
      rproxy = 1;
      # Enable upload database for unpost, dedup
      e2d = true;
      # Enable audio metadata indexing
      e2ts = true;
      # Enable file hashing for dedup
      e2dsa = true;
      # Store index database and thumbnails in a central cache dir
      # instead of creating .hist/ subdirectories inside each volume.
      hist = "/var/cache/copyparty";
    };

    accounts = {
      sylvester = {
        passwordFile = config.sops.secrets."copyparty/sylvester-password".path;
      };
    };

    volumes = {
      "/" = {
        path = "/srv/media";
        access.rwmd = [ "sylvester" ];
        flags = mediaFlags;
      };
      "/PARA" = {
        path = "/home/sylvester/PARA";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/agent-vault" = {
        path = "/home/sylvester/.local/share/agent-vault";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/Documents" = {
        path = "/home/sylvester/Documents";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/Miscellaneous" = {
        path = "/home/sylvester/Miscellaneous";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/Music" = {
        path = "/home/sylvester/Music";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/Pictures" = {
        path = "/home/sylvester/Pictures";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/Projects" = {
        path = "/home/sylvester/Projects";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
      "/Videos" = {
        path = "/home/sylvester/Videos";
        access.rwmd = [ "sylvester" ];
        flags = homeFlags;
      };
    };
  };

  # Reverse proxy via Caddy
  services.caddy.virtualHosts."files.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };

  # copyparty must be a member of the groups it chowns uploads to (gid flag);
  # media also gives it read access to /srv/media.
  users.users.copyparty.extraGroups = [
    "media"
    "users"
  ];

  # Grant the copyparty user rwx access to the home-directory volumes via ACLs
  # so it can serve and manage existing content. Uses systemd-tmpfiles 'a+'
  # type to set recursive ACLs.
  systemd.tmpfiles.rules = [
    "a+ /home/sylvester/PARA - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/.local/share/agent-vault - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/Documents - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/Miscellaneous - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/Music - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/Pictures - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/Projects - - - - u:copyparty:rwx,d:u:copyparty:rwx"
    "a+ /home/sylvester/Videos - - - - u:copyparty:rwx,d:u:copyparty:rwx"
  ];

  # Ensure copyparty service waits for /srv mount
  systemd.services.copyparty.unitConfig.RequiresMountsFor = "/srv";
}
