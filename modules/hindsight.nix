# Hindsight: the long-term memory server Hermes recalls from and retains to.
# One container on the host network, listening on loopback only, keeping its
# data in the host PostgreSQL. Extraction runs on Claude Haiku through the
# Claude subscription: the image's Claude CLI reads a `claude setup-token`
# token from CLAUDE_CODE_OAUTH_TOKEN.
{
  flake.modules.nixos.hindsight =
    { config, ... }:
    let
      postgres = config.services.postgresql;
      secrets = config.sops.secrets;
    in
    {
      sops.secrets = {
        # Only the role's SCRAM hash lives in PostgreSQL; the setup unit reads
        # the plaintext to set it.
        "hindsight/db-password".owner = "postgres";
        "hindsight/claude-token" = { };
      };

      sops.templates."hindsight.env" = {
        restartUnits = [ "podman-hindsight.service" ];
        content = ''
          HINDSIGHT_API_DATABASE_URL=postgresql://hindsight:${
            config.sops.placeholder."hindsight/db-password"
          }@127.0.0.1:${toString postgres.settings.port}/hindsight
          CLAUDE_CODE_OAUTH_TOKEN=${config.sops.placeholder."hindsight/claude-token"}
        '';
      };

      services.postgresql = {
        enable = true;
        extensions = ps: [ ps.pgvector ];
        ensureDatabases = [ "hindsight" ];
        ensureUsers = [
          {
            name = "hindsight";
            ensureDBOwnership = true;
          }
        ];
        # Ahead of the default `host all all 127.0.0.1/32 md5` line, so the
        # role logs in with SCRAM only.
        authentication = ''
          host hindsight hindsight 127.0.0.1/32 scram-sha-256
        '';
      };

      # Sets the role's password and creates the vector extension, which needs
      # a superuser.
      systemd.services.hindsight-db = {
        requires = [ "postgresql.target" ];
        after = [ "postgresql.target" ];
        environment.PGPORT = toString postgres.settings.port;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
        };
        script = ''
          ${postgres.finalPackage}/bin/psql -d hindsight -v ON_ERROR_STOP=1 <<'SQL'
          \set password `cat ${secrets."hindsight/db-password".path}`
          ALTER ROLE hindsight WITH LOGIN PASSWORD :'password';
          CREATE EXTENSION IF NOT EXISTS vector;
          SQL
        '';
      };

      virtualisation.oci-containers.containers.hindsight = {
        image = "ghcr.io/vectorize-io/hindsight:0.10.2";
        extraOptions = [ "--network=host" ];
        environmentFiles = [ config.sops.templates."hindsight.env".path ];
        environment = {
          HINDSIGHT_API_HOST = "127.0.0.1";
          HINDSIGHT_CP_HOSTNAME = "127.0.0.1";
          HINDSIGHT_API_LLM_PROVIDER = "claude-code";
          HINDSIGHT_API_LLM_MODEL = "claude-haiku-4-5";
          HINDSIGHT_API_WORKER_ID = config.networking.hostName;
        };
      };

      systemd.services.podman-hindsight = {
        requires = [ "hindsight-db.service" ];
        after = [ "hindsight-db.service" ];
      };
    };
}
