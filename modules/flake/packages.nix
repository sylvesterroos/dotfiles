{ config, inputs, ... }:
{
  flake.overlays = import "${inputs.self}/overlays" {
    inherit inputs;
    mv = config.multiverse;
  };

  perSystem =
    { pkgs, ... }:
    {
      packages = import "${inputs.self}/pkgs" pkgs;
    };
}
