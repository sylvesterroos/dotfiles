# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  mpatch = pkgs.callPackage ./mpatch { };
  switch-to-previous-desktop = pkgs.callPackage ./switch-to-previous-desktop { };
}
