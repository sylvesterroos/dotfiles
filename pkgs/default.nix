# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  mpatch = pkgs.callPackage ./mpatch { };
  switch-to-previous-desktop = pkgs.callPackage ./switch-to-previous-desktop { };
  omawrite = pkgs.callPackage ./omawrite { };
  # SDDM with PR #2204 backport (Wayland VT fix, upstream bug #2129)
  sddm-vt-fix = pkgs.callPackage ./sddm-vt-fix { };
}
