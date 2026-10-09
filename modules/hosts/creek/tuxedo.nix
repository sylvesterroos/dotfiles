{ inputs, ... }:
{
  flake.modules.nixos.creek = {
    hardware.tuxedo-drivers.enable = true;

    imports = [ inputs.nixos-hardware.nixosModules.tuxedo-pulse-15-gen2 ];

    # WirePlumber starts the built-in mic at 1.0, the codec's full analog gain
    # (+30 dB on this laptop), which clips speech. 0.33³ is 33% on the cubic
    # volume scale, close to unity there. Routes with a saved volume keep it.
    services.pipewire.wireplumber.extraConfig.default-source-volume."wireplumber.settings" = {
      "device.routes.default-source-volume" = 0.036;
    };
  };
}
