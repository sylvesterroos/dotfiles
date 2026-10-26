# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  switch-to-previous-desktop = pkgs.callPackage ./switch-to-previous-desktop { };
  playkeeper = pkgs.callPackage ./playkeeper { };
  proton-drive-cli = pkgs.callPackage ./proton-drive-cli { };
}
