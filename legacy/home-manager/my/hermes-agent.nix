{
  config,
  lib,
  mv,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.my.hermes-agent;
  hermesEnv = import ../../shared/hermes-agent.nix {
    inherit lib mv pkgs;
    cuaDriver = if pkgs.stdenv.isLinux then inputs.cua.packages.${pkgs.system}.cua-driver else null;
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
