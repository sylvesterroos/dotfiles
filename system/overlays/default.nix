# This file defines overlays
{ inputs, ... }:
{
  additions =
    final: prev:
    {
      ghostty-git = inputs.ghostty.packages.${prev.system}.default;
      nix-alien = inputs.nix-alien.packages.${prev.system}.default;
      gitu = inputs.gitu.packages.${prev.system}.default;
    }
    # This one brings our custom packages from the 'pkgs' directory
    // (import ../pkgs final.pkgs);

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  # unstable-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
}
