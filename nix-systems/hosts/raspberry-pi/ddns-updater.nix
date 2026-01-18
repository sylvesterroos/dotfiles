{ config, ... }:
{
  services.ddns-updater = {
    enable = true;
    environment = {
      SERVER_ENABLED = "no";
      CONFIG_FILEPATH = "/run/credentials/ddns-updater.service/config_file";
      PERIOD = "5m";
    };
  };

  systemd.services.ddns-updater.serviceConfig.LoadCredential = [
    "config_file:${config.sops.secrets.ddns-updater-config.path}"
  ];
}
