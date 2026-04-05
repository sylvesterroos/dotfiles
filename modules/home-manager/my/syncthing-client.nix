{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.syncthing-client;
in
{
  options.my.syncthing-client = {
    enable = mkEnableOption "syncthing-client" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      extraOptions = [ ];
      guiAddress = "127.0.0.1:8384";
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        options = {
          relaysEnabled = false;
          globalAnnounceEnabled = false;
          localAnnounceEnabled = true;
        };

        devices = {
          "server" = {
            id = "AUD4ZEW-3FPD6WU-U6DAAHL-V7WAH7P-XPJD6RN-GFIDXTI-GLVU5E2-WMTQ5A4";
            addresses = [ "tcp://raspberry-pi:22000" ];
          };
        };

        folders = {
          "PARA" = {
            path = "~/PARA";
            devices = [ "server" ];
          };
          "agent-vault" = {
            path = "~/.local/share/agent-vault";
            devices = [ "server" ];
          };
        };
      };
    };
  };
}
