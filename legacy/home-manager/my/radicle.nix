{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.radicle;
in
{
  options.my.radicle = {
    enable = mkEnableOption "radicle" // {
      default = true;
    };
    alias = mkOption {
      type = types.str;
      description = "Human readable alias for your radicle node.";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [ "radicle-node-1.10.3" ];

    warnings = [
      "Radicle private repositories are insecure: node traffic is neither encrypted nor authenticated. Use public repositories only."
    ];

    home.packages =
      with pkgs;
      [ ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        radicle-desktop
      ];

    programs.radicle = {
      enable = true;
      settings.node.alias = cfg.alias;
    };

    services.radicle.node = {
      enable = true;
      lazy.enable = true;
    };
  };
}
