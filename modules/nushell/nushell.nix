{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    let

      # Bake the `devenv hook nu` output into the store so we don't regenerate it
      # on every shell startup. See https://devenv.sh/auto-activation/
      devenvHookNu = pkgs.runCommand "devenv-hook.nu" { nativeBuildInputs = [ pkgs.devenv ]; } ''
        devenv hook nu > $out
      '';
    in
    {
      programs.nushell = {
        enable = true;

        configFile.source = ./config.nu;

        extraConfig = ''
          ${builtins.readFile ./functions/gw.nu}

          source ${devenvHookNu}
        '';

        shellAliases = {
          vi = "hx";
          vim = "hx";
          nano = "hx";
        };
      };

      home.packages = with pkgs; [ nufmt ];

      # Completions
      programs.fish.enable = true;
      programs.carapace = {
        enable = true;
        enableNushellIntegration = true;
      };

      xdg.configFile."topiary/languages.ncl".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/blindFS/topiary-nushell/main/languages.ncl";
        sha256 = "sha256-VX4peVa8RV/jgQWro5Supp7DRi5HBsnmU6ZaYAPf59s=";
      };

      xdg.configFile."topiary/queries/nu.scm".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/blindFS/topiary-nushell/main/queries/nu.scm";
        sha256 = "sha256-78UggUotcfH9IoZ5COISYYEPSL69SPdkQuNXi95CMJU=";
      };
    };
}
