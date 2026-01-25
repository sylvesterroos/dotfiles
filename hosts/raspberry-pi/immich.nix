{
  config,
  patchedNixpkgsStable,
  ...
}: {
  disabledModules = ["services/web-apps/immich.nix"];
  imports = [
    "${patchedNixpkgsStable}/nixos/modules/services/web-apps/immich.nix"
  ];

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    environment = {
      IMMICH_LOG_LEVEL = "verbose";
    };
    database.port = 5431;
    machine-learning.enable = false;
  };

  # Hardware acceleration
  # `null` will give access to all devices.
  services.immich.accelerationDevices = null;
  hardware.raspberry-pi."4".fkms-3d.enable = true;
  users.users.immich.extraGroups = ["video" "render"];

  services.caddy.virtualHosts."immich.sylvesterroos.com".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.immich.port}
  '';
}
