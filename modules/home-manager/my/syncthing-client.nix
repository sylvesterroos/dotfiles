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
            id = "YKOUMV6-X53SWZN-CB6SXTD-VVP6LH7-YKLGURY-OQLNYLD-HV4NP26-GLUOCAE";
            addresses = [ "tcp://bachus:22000" ];
          };
        };

        folders = {
          "PARA" = {
            path = "~/PARA";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "agent-vault" = {
            path = "~/.local/share/agent-vault";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Documents" = {
            path = "~/Documents";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Miscellaneous" = {
            path = "~/Miscellaneous";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Music" = {
            path = "~/Music";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Pictures" = {
            path = "~/Pictures";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Projects" = {
            path = "~/Projects";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
          "Videos" = {
            path = "~/Videos";
            devices = [ "server" ];
            ignorePatterns = [ "(?d).git" ];
          };
        };
      };
    };
  };
}
