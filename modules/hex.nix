{ inputs, ... }:
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      imports = [ inputs.hex.homeManagerModules.hex ];

      programs.hex = {
        enable = true;
        autostart = true;
        # Hex loads the host's Mesa into its own process, and Mesa needs the
        # glibc it was built with. Build upstream's recipe with the nixpkgs
        # this host runs instead of the nixpkgs the flake input follows.
        package = (pkgs.callPackage "${inputs.hex}/nix/package.nix" { }).overrideAttrs {
          # Upstream's rune outputHash lags its Cargo.lock rev 7d3ee6ca.
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = "${inputs.hex}/Cargo.lock";
            outputHashes = {
              "transcribe-rs-0.3.11" = "sha256-MJJiug3LfbKsuHcL2+LJk95+j5kk/MWzb5ihdBlHLmE=";
              "rune-0.0.1" = "sha256-FGgfrqN9OaygnVhtE2K0C85wq3aicF+ep2F10aKVd/E=";
              "transcribe-cpp-sys-0.4.1" = "sha256-BAc2qKUMBZ5D6+Bq12NaZ1+ntWxHv95TYcAMTt3a5X8=";
            };
          };
        };
      };
    };
}
