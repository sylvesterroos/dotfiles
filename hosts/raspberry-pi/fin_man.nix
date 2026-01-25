{
  config,
  lib,
  ...
}:
{
  services.fin_man = {
    enable = true;
    server = {
      secretKeyBaseFile = config.sops.secrets."fin_man/secret_key_base".path;
      listenAddress = "0.0.0.0";
    };
  };
  systemd.services.fin_man.environment =
    let
      dbname = config.services.fin_man.database.postgres.dbname;
      socket = config.services.fin_man.database.postgres.socket;
      port = toString config.services.postgresql.settings.port;
    in
    {
      DATABASE_URL = lib.mkForce "postgresql:///${dbname}?host=${socket}&port=${port}";
      PHX_HOST = "raspberry-pi";
    };
}
