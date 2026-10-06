{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      postgresPort = toString config.services.postgresql.settings.port;
    in
    {
      sops.secrets.plausible-secret-key = { };

      services.plausible = {
        enable = true;
        # Plausible's runtime config ignores the URL port when DATABASE_URL uses a
        # Unix socket. Patch it so Bachus can keep PostgreSQL on its non-default
        # port while still using socket/peer authentication instead of TCP auth.
        package = pkgs.plausible.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            ${pkgs.buildPackages.python3}/bin/python3 - <<'PY'
            import os
            from pathlib import Path

            old = """    socket_dir: socket_dir,
                database: database"""
            new = """    socket_dir: socket_dir,
                database: database,
                port:
                  db_uri.port ||
                    ((db_uri.query || "") |> URI.decode_query() |> Map.get("port", "5432") |> String.to_integer())"""

            runtime_files = list(Path(os.environ["out"]).glob("releases/*/runtime.exs"))
            if len(runtime_files) != 1:
                raise SystemExit(f"expected one Plausible runtime.exs, found {runtime_files}")

            runtime_file = runtime_files[0]
            text = runtime_file.read_text()
            if old not in text:
                raise SystemExit("Plausible runtime socket database config changed")

            runtime_file.write_text(text.replace(old, new, 1))
            PY
          '';
        });

        database = {
          clickhouse.url = "http://127.0.0.1:18123/default";
          # The Plausible module's PostgreSQL setup unit hardcodes port 5432,
          # but Bachus runs PostgreSQL on a non-default port to avoid local
          # development collisions. Disable it and provide a port-aware setup
          # unit below.
          postgres.setup = false;
          postgres.socket = "/run/postgresql";
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

        # The Plausible module builds DATABASE_URL without a port, but Bachus runs
        # PostgreSQL on a non-default port to avoid local development collisions.
        environment.DATABASE_URL = lib.mkForce "postgresql:///plausible?host=/run/postgresql&port=${postgresPort}";
      };

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
