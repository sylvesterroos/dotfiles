{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.agents;
  agentTools = import ../../shared/agents.nix { inherit pkgs; };
in
{
  options.my.agents = {
    enable = mkEnableOption "shared agent tools" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = agentTools.packages;
  };
}
