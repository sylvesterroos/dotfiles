# Hindsight: the long-term memory server Hermes recalls from and retains to.
# One `hindsight-api` process from llm-agents, listening on loopback only and
# keeping its data in the host PostgreSQL. The API process also runs the
# worker that extracts and consolidates memories. Extraction runs on Claude
# Haiku through OpenRouter, paid with the work OpenRouter key, since the server
# holds both personal and work banks.
#
# The stored vectors come from the local embeddings and reranker models, so
# the package carries its local-ml extra. A remote embeddings provider would
# change the vectors and require re-embedding every memory. The server runs
# its schema migrations on startup and they only go forward: take a
# `pg_dump hindsight` before moving to a new version.
{ inputs, ... }:
{
  flake.modules.nixos.hindsight =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      postgres = config.services.postgresql;
      secrets = config.sops.secrets;
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      hindsight = llmAgents.hindsight.overridePythonAttrs (old: {
        dependencies = old.dependencies ++ old.optional-dependencies.local-ml;
      });
    in
    {
      sops.secrets = {
        # Only the role's SCRAM hash lives in PostgreSQL; the setup unit reads
        # the plaintext to set it.
        "hindsight/db-password".owner = "postgres";
        "hindsight/openrouter-api-key" = { };
      };

      sops.templates."hindsight.env" = {
        restartUnits = [ "hindsight.service" ];
        content = ''
          HINDSIGHT_API_DATABASE_URL=postgresql://hindsight:${
            config.sops.placeholder."hindsight/db-password"
          }@127.0.0.1:${toString postgres.settings.port}/hindsight
          HINDSIGHT_API_LLM_API_KEY=${config.sops.placeholder."hindsight/openrouter-api-key"}
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

      systemd.services.hindsight = {
        description = "Hindsight memory server";
        wantedBy = [ "multi-user.target" ];
        requires = [ "hindsight-db.service" ];
        wants = [ "network-online.target" ];
        after = [
          "hindsight-db.service"
          # The local models download on first start.
          "network-online.target"
        ];
        environment = {
          HINDSIGHT_API_HOST = "127.0.0.1";
          HINDSIGHT_API_LLM_PROVIDER = "openrouter";
          HINDSIGHT_API_LLM_MODEL = "anthropic/claude-haiku-5.5";
          # Gather facts between the daily consolidation runs.
          HINDSIGHT_API_ENABLE_AUTO_CONSOLIDATION = "false";
          HINDSIGHT_API_CONSOLIDATION_LLM_BATCH_SIZE = "16";
          HINDSIGHT_API_WORKER_ID = config.networking.hostName;
          HOME = "/var/lib/hindsight";
          HF_HOME = "/var/lib/hindsight/huggingface";
        };
        serviceConfig = {
          ExecStart = lib.getExe hindsight;
          EnvironmentFile = config.sops.templates."hindsight.env".path;
          DynamicUser = true;
          StateDirectory = "hindsight";
          PrivateTmp = true;
          Restart = "on-failure";
        };
      };

      systemd.services.hindsight-consolidate = {
        description = "Consolidate accumulated Hermes memories in every bank";
        requires = [ "hindsight.service" ];
        after = [ "hindsight.service" ];
        path = [
          pkgs.curl
          pkgs.jq
        ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
        };
        script = ''
          api=http://127.0.0.1:8888/v1/default/banks
          for bank in $(curl --fail --silent --show-error --max-time 30 "$api?limit=1000" | jq -r '.banks[].bank_id'); do
            stats=$(curl --fail --silent --show-error --max-time 30 "$api/$bank/stats")
            if [ "$(printf '%s' "$stats" | jq -r '.failed_consolidation')" -gt 0 ]; then
              curl --fail --silent --show-error --max-time 30 \
                --request POST "$api/$bank/consolidation/recover"
            fi
            if printf '%s' "$stats" | jq -e '.pending_consolidation + .failed_consolidation > 0' > /dev/null; then
              curl --fail --silent --show-error --max-time 30 \
                --request POST --header 'Content-Type: application/json' \
                --data '{}' "$api/$bank/consolidate"
            fi
          done
        '';
      };

      systemd.timers.hindsight-consolidate = {
        enable = true;
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 04:00:00 Europe/Amsterdam";
          # Run a missed consolidation once bachus is back up.
          Persistent = true;
        };
      };
    };
}
