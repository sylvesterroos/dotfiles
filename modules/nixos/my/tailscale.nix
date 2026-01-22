{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.my.tailscale;
in
{
  options.my.tailscale = {
    enable = mkEnableOption "tailscale" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    environment.systemPackages = with pkgs; [ trayscale ];
  };
}
