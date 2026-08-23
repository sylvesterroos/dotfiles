{
  config,
  lib,
  mv,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.hermes-agent;
  hermesEnv = import ../../shared/hermes-agent.nix {
    inherit lib mv pkgs;
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
