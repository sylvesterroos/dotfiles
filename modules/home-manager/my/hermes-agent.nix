{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.hermes-agent;
  hermesEnv = import ../../shared/hermes-agent.nix {
    inherit lib pkgs;
  };
in
{
  options.my.hermes-agent = {
    enable = mkEnableOption "hermes agent" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = hermesEnv.packages;

    home.sessionVariables = hermesEnv.sessionVariables;
  };
}
