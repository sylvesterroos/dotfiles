{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.nushell;
in
{
  options.my.nushell = {
    enable = mkEnableOption "nushell" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;

      configFile.source = ./config.nu;

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
      sha256 = "sha256-9mBsAwNapIT+HHj8vRyLBTuR3Skmm0aN4wCaDwG2gzg=";
    };

    xdg.configFile."topiary/queries/nu.scm".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/blindFS/topiary-nushell/main/queries/nu.scm";
      sha256 = "sha256-2o7oIFkxuy8u8HNkiEzNnoKekmwaxClCWQnQg3rgVeU=";
    };
  };
}
