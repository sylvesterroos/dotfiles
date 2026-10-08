# Hindsight: the long-term memory server Hermes recalls from and retains to.
# One container on the host network, listening on loopback only, keeping its
# data in the host PostgreSQL. Extraction runs on Claude Haiku through the
# Claude subscription: the image's Claude CLI reads a `claude setup-token`
# token from CLAUDE_CODE_OAUTH_TOKEN.
{
  flake.modules.nixos.hindsight =
    { config, pkgs, ... }:
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
        image = "ghcr.io/vectorize-io/hindsight:latest";
        labels."io.containers.autoupdate" = "registry";
        extraOptions = [ "--network=host" ];
        environmentFiles = [ config.sops.templates."hindsight.env".path ];
        environment = {
          HINDSIGHT_API_HOST = "127.0.0.1";
          HINDSIGHT_CP_HOSTNAME = "127.0.0.1";
          HINDSIGHT_API_LLM_PROVIDER = "claude-code";
          HINDSIGHT_API_LLM_MODEL = "claude-haiku-5-5";
          # Gather facts between scheduled consolidation runs.
          HINDSIGHT_API_ENABLE_AUTO_CONSOLIDATION = "false";
          HINDSIGHT_API_CONSOLIDATION_LLM_BATCH_SIZE = "16";
          HINDSIGHT_API_WORKER_ID = config.networking.hostName;
        };
      };

      systemd.services.hindsight-consolidate = {
        description = "Consolidate accumulated Hermes memories";
        requires = [ "podman-hindsight.service" ];
        after = [ "podman-hindsight.service" ];
        path = [
          pkgs.curl
          pkgs.jq
        ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
        };
        script = ''
          bank=http://127.0.0.1:8888/v1/default/banks/hermes
          # Snapshot every page before retries change the failed-operation list.
          offset=0
          retry_ids=""
          while :; do
            page=$(curl --fail --silent --show-error --max-time 30 \
              "$bank/operations?status=failed&type=retain&exclude_parents=true&limit=100&offset=$offset")
            cooldown_ids=$(printf '%s' "$page" | jq -r '
              .operations[]
              | select((.error_message // "") | contains("Claude Code reported an error: You\u0027ve hit your session limit"))
              | .operation_id
            ')
            retry_ids="$retry_ids $cooldown_ids"
            offset=$((offset + 100))
            if [ "$offset" -ge "$(printf '%s' "$page" | jq -r '.total')" ]; then
              break
            fi
          done
          for operation_id in $retry_ids; do
            curl --fail --silent --show-error --max-time 30 \
              --request POST "$bank/operations/$operation_id/retry"
          done

          stats=$(curl --fail --silent --show-error --max-time 30 "$bank/stats")
          if [ "$(printf '%s' "$stats" | jq -r '.failed_consolidation')" -gt 0 ]; then
            curl --fail --silent --show-error --max-time 30 \
              --request POST "$bank/consolidation/recover"
          fi
          if printf '%s' "$stats" | jq -e '.pending_consolidation + .failed_consolidation > 0' > /dev/null; then
            curl --fail --silent --show-error --max-time 30 \
              --request POST --header 'Content-Type: application/json' \
              --data '{}' "$bank/consolidate"
          fi
        '';
      };

      systemd.timers.hindsight-consolidate = {
        enable = false;
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/30";
          Persistent = true;
        };
      };

      systemd.services.podman-hindsight = {
        requires = [ "hindsight-db.service" ];
        after = [ "hindsight-db.service" ];
      };
    };
}
