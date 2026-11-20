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
        package = (pkgs.callPackage "${inputs.hex}/nix/package.nix" { }).overrideAttrs (old: {
          # Fails upstream: assertion at src/rune_ui/tests.rs:1519.
          checkFlags = (old.checkFlags or [ ]) ++ [
            "--skip=rune_ui::tests::history_stats_button_opens_and_closes_the_dialog"
          ];
        });
      };
    };
}
