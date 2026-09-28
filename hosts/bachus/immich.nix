{
  config,
  mv,
  patchedNixpkgsStable,
  ...
}:
{
  disabledModules = [ "services/web-apps/immich.nix" ];
  imports = [
    "${patchedNixpkgsStable}/nixos/modules/services/web-apps/immich.nix"
  ];

  services.immich = {
    enable = true;
    package = mv.tip.immich;
    mediaLocation = "/srv/media/immich";
    host = "0.0.0.0";
    environment = {
      IMMICH_LOG_LEVEL = "verbose";
    };
    database.port = 5431;
    machine-learning.enable = false;
  };
  # Tailnet-only via tailnet-services.nix; the port stays firewalled.
}
