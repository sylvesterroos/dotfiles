# This file defines overlays
{ inputs, ... }:
let
  patchedNixpkgsStableFor =
    system:
    (import inputs.nixpkgs-stable { inherit system; }).applyPatches {
      name = "nixpkgs-patched";
      src = inputs.nixpkgs-stable;
      patches = [
        ./patches/immich-postgres-unix-socket-port.patch
      ];
    };
in
{
  # TODO: remove once PR is merged
  # https://github.com/NixOS/nixpkgs/pull/481056
  patched-nixpkgs-stable = patchedNixpkgsStableFor;

  additions =
    final: prev:
    {
      nix-alien = inputs.nix-alien.packages.${prev.stdenv.hostPlatform.system}.default;
      fpatch = inputs.fpatch.packages.${prev.stdenv.hostPlatform.system}.default;
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
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
