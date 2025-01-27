# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: { magit = pkgs.callPackage ./magit { }; } # TODO: make magit-nix a flake input instead of a submodule
