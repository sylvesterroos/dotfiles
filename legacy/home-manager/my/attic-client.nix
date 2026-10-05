{ config, lib, ... }:
with lib;
let
  cfg = config.my.attic-client;
  atticShared = import ../../shared/attic.nix { };
in
{
  options.my.attic-client = {
    enable = mkEnableOption "attic push client" // {
      default = false;
    };
    token = mkOption {
      type = types.str;
      description = "Name of the sops secret holding the attic push token";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."${cfg.token}" = { };

    programs.attic-client = {
      enable = true;
      settings = {
        default-server = atticShared.host;
        servers.${atticShared.host} = {
          endpoint = atticShared.endpoint;
          token-file = config.sops.secrets."${cfg.token}".path;
        };
      };
      watchStore = [ atticShared.host ];
    };

    systemd.user.services."attic-watch-store--${atticShared.host}".Unit.After = [ "sops-nix.service" ];
  };
}
