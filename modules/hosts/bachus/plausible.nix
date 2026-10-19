{
  flake.modules.nixos.bachus =
    {
      config,
      pkgs,
      ...
    }:
    let
      postgresPort = toString config.services.postgresql.settings.port;
      plausibleSocketDir = "/run/plausible-postgres";
    in
    {
      sops.secrets.plausible-secret-key = { };

      services.plausible = {
        enable = true;

        database = {
          clickhouse.url = "http://127.0.0.1:18123/default";
          # The Plausible module's PostgreSQL setup unit hardcodes port 5432,
          # but Bachus runs PostgreSQL on a non-default port to avoid local
          # development collisions. Disable it and provide a port-aware setup
          # unit below.
          postgres.setup = false;
          # Postgrex ignores the URL port for Unix sockets and always opens
          # .s.PGSQL.5432, so point it at a directory where that name links to
          # the real socket. This keeps peer authentication and the stock,
          # binary-cached package.
          postgres.socket = plausibleSocketDir;
        };

        server = {
          baseUrl = "https://plausible.sylvesterroos.com";
          disableRegistration = true;
          listenAddress = "127.0.0.1";
          port = 18080;
          secretKeybaseFile = config.sops.secrets.plausible-secret-key.path;
        };
      };

      services.clickhouse.serverConfig = {
        http_port = 18123;
        tcp_port = 19000;
        # ClickHouse must be UTC: Plausible sends naive datetime strings in queries,
        # and ClickHouse parses them in its local timezone. With Europe/Amsterdam
        # (UTC+2), all query time ranges shift 2h into the past, breaking graphs.
        timezone = "UTC";
      };

      # Public: sylvesterroos.com loads the tracking script from here.
      services.caddy.virtualHosts."plausible.sylvesterroos.com".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.plausible.server.port}
      '';

      systemd.services.plausible = {
        after = [
          "postgresql.target"
          "plausible-postgres.service"
        ];
        requires = [
          "postgresql.target"
          "plausible-postgres.service"
        ];
      };

      systemd.tmpfiles.rules = [
        "d ${plausibleSocketDir} 0755 root root -"
        "L+ ${plausibleSocketDir}/.s.PGSQL.5432 - - - - /run/postgresql/.s.PGSQL.${postgresPort}"
      ];

      systemd.services.plausible-postgres = {
        after = [ "postgresql.target" ];
        partOf = [ "plausible.service" ];

        serviceConfig = {
          Type = "oneshot";
          User = config.services.postgresql.superUser;
          RemainAfterExit = true;
        };

        script = ''
          PSQL() {
            ${config.services.postgresql.package}/bin/psql --port=${postgresPort} "$@"
          }
          if ! PSQL -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'plausible'" | ${pkgs.gnugrep}/bin/grep -qx 1; then
            PSQL -tAc "CREATE ROLE plausible WITH LOGIN;"
          fi

          if ! PSQL -lqt | ${pkgs.coreutils}/bin/cut -d \| -f 1 | ${pkgs.gnugrep}/bin/grep -qw plausible; then
            PSQL -tAc "CREATE DATABASE plausible WITH OWNER plausible;"
          fi

          PSQL -d plausible -tAc "CREATE EXTENSION IF NOT EXISTS citext;"
        '';
      };
    };
}
