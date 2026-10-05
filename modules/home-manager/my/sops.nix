{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.sops;
  sopsShared = import ../../shared/sops.nix {
    inherit lib pkgs;
  };
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  options.my.sops = {
    enable = mkEnableOption "sops-nix (home-manager)" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = sopsShared.tools;

    sops = sopsShared.settings // {
    };
  };
}
