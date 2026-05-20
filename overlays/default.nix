# This file defines overlays
{ inputs, ... }:
let
  patchedNixpkgsStableFor =
    system: nixpkgs:
    (import nixpkgs { inherit system; }).applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [
        ./patches/immich-postgres-unix-socket-port.patch
      ];
    };

  # Use the baseline (non-AVX2) bun binary for older CPUs
  bun-baseline-overlay = final: prev: {
    bun = prev.bun.overrideAttrs (oldAttrs: {
      src = prev.fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${oldAttrs.version}/bun-linux-x64-baseline.zip";
        hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
      };
    });
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

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
  unstable-packages-baseline = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [ bun-baseline-overlay ];
    };
  };
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
