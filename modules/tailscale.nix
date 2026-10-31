{
  flake.modules.nixos.base = {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
  };

  flake.modules.nixos.desktop.services.tailscale.extraSetFlags = [ "--operator=sylvester" ];

  flake.modules.homeManager.desktop =
    { osConfig, ... }:
    {
      services.tailscale-systray = {
        enable = true;
        package = osConfig.services.tailscale.package;
      };
    };
}
