{
  ...
}:

{
  # HA binds 0.0.0.0 (host network), so the firewall allows LAN clients to reach it directly;
  networking.firewall.allowedTCPPorts = [ 8123 ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Amsterdam";
      pull = "newer";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions =
        let
          zigbeeDongleDevice = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_62e4d8598c12f011b2b8fd13773d9da9-if00-port0";
        in
        [
          # Use the host network namespace for all sockets
          "--network=host"
          # Pass devices into the container, so Home Assistant can discover and make use of them
          "--device=${zigbeeDongleDevice}:${zigbeeDongleDevice}"
        ];
    };
  };
}
