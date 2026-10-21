{ config, ... }:
let
  mv = config.multiverse;
  inherit (config) serviceFrom;
in
{
  flake.modules.nixos.bachus =
    { ... }:
    {
      imports = [
        (serviceFrom {
          pkgs = mv.tip;
          name = "immich";
          module = "services/web-apps/immich.nix";
        })
      ];

      services.immich = {
        enable = true;
        mediaLocation = "/srv/media/immich";
        host = "0.0.0.0";
        environment = {
          IMMICH_LOG_LEVEL = "verbose";
        };
        database.port = 5431;
        machine-learning.enable = false;
      };
      # Tailnet-only via tailnet-services.nix; the port stays firewalled.
    };
}
