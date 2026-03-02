# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  mcp_proxy_rust = pkgs.callPackage ./mcp_proxy_rust { };
  mpatch = pkgs.callPackage ./mpatch { };
}
