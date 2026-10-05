{ inputs, mv, ... }:
{
  flake.overlays = import ../../overlays { inherit inputs mv; };

  perSystem =
    { pkgs, ... }:
    {
      packages = import ../../pkgs pkgs;
    };
}
