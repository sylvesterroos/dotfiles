{
  config,
  ...
}:
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
        access = {
          rwmd = [ "sylvester" ];
        };
        flags = {
          grid = true;
        };
      };
      "/PARA" = {
        path = "/home/sylvester/PARA";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/agent-vault" = {
        path = "/home/sylvester/.local/share/agent-vault";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/Documents" = {
        path = "/home/sylvester/Documents";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/Miscellaneous" = {
        path = "/home/sylvester/Miscellaneous";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/Music" = {
        path = "/home/sylvester/Music";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/Pictures" = {
        path = "/home/sylvester/Pictures";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/Projects" = {
        path = "/home/sylvester/Projects";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
      "/Videos" = {
        path = "/home/sylvester/Videos";
        access.rwmd = [ "sylvester" ];
        flags.grid = true;
      };
    };
  };

  # Reverse proxy via Caddy
  services.caddy.virtualHosts."files.sylvesterroos.com" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3923
    '';
  };

  # Allow copyparty to read /srv/media (via media group).
  users.users.copyparty.extraGroups = [ "media" ];

  # Grant the copyparty user read access to syncthing directories via ACLs
  # Uses systemd-tmpfiles 'a+' type to set recursive ACLs.
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
