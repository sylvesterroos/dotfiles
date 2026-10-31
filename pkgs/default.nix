# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  switch-to-previous-desktop = pkgs.callPackage ./switch-to-previous-desktop { };
  playkeeper = pkgs.callPackage ./playkeeper { };
  proton-drive-cli = pkgs.callPackage ./proton-drive-cli { };
  wine-icon = pkgs.callPackage ./wine-icon { };
  # Hermes builds these against its own interpreter; these attributes serve
  # builds and updates.
  hermes-plugin-hindsight = pkgs.callPackage ./hermes-plugin-hindsight {
    pythonPackages = pkgs.python3Packages;
  };
  hermes-plugin-homeassistant = pkgs.callPackage ./hermes-plugin-homeassistant {
    pythonPackages = pkgs.python3Packages;
  };
  hindsight-client = pkgs.callPackage ./hindsight-client {
    pythonPackages = pkgs.python3Packages;
  };
}
