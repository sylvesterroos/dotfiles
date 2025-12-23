{
  config,
  pkgs,
  lib,
  ...
}: {
  services.fin_man = {
    enable = true;
    server = {
      secretKeyBaseFile = config.sops.secrets."fin_man/secret_key_base".path;
    };
  };
  services.postgresql = {
    package = pkgs.postgresql_18_jit;
    # non-default port so we don't get in the way of development postgres instances
    settings.port = 5431;
  };
  systemd.services.fin_man.environment = let
    dbname = config.services.fin_man.database.postgres.dbname;
    socket = config.services.fin_man.database.postgres.socket;
    port = toString config.services.postgresql.settings.port;
  in {
    DATABASE_URL = lib.mkForce "postgresql:///${dbname}?host=${socket}&port=${port}";
    # TODO: set to reverse proxy virtual host
    PHX_HOST = "localhost";
  };
}
