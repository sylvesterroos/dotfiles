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
    enable = mkEnableOption "shared agent tools (NixOS-level)";
    user = mkOption {
      type = types.str;
      default = "sylvester";
    };
  };

  config = mkIf cfg.enable {
    # Install into the user's NixOS profile (/etc/profiles/per-user/$USER),
    # which puts the packages on that user's PATH only.
    users.users.${cfg.user}.packages = agentTools.packages;
  };
}
