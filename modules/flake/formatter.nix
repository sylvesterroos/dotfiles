{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        programs.nixfmt.enable = true;
        programs.jsonfmt.enable = true;
        programs.yamlfmt.enable = true;
        programs.taplo.enable = true;

        # treefmt-nix has no nufmt module.
        settings.formatter.nufmt = {
          command = "${pkgs.nufmt}/bin/nufmt";
          includes = [ "*.nu" ];
        };

        # sops: the YAML MAC covers the whole tree.
        # Zed: JSONC, comments are part of the format.
        settings.excludes = [
          "secrets/*.yaml"
          "**/zed/*.json"
          ".zed/settings.json"
        ];
      };
    };
}
