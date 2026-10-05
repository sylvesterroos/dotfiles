{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.postgresql;
in
{
  options.my.postgresql.dbaUsers = mkOption {
    type = types.listOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            userName = mkOption {
              type = types.str;
              description = "Linux system username to grant DBA privileges";
            };

            superuser = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to grant SUPERUSER privileges (full control)";
            };

            mapName = mkOption {
              type = types.str;
              default = "dba-${config.userName}";
              description = "Name of the ident mapping (auto-generated per user)";
            };
          };
        }
      )
    );
    default = [ ];
    description = "Linux users to grant PostgreSQL DBA privileges";
  };

  config = mkIf (config.services.postgresql.enable && cfg.dbaUsers != [ ]) {
    services.postgresql = {
      ensureUsers = map (user: {
        name = user.userName;
        ensureDBOwnership = true;
        ensureClauses = {
          login = true;
          superuser = user.superuser;
        };
      }) cfg.dbaUsers;

      ensureDatabases = map (user: user.userName) cfg.dbaUsers;
    };
  };
}
