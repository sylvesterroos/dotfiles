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
        package = pkgs.callPackage "${inputs.hex}/nix/package.nix" { };
      };
    };
}
