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
    # Default false: creek and delta already get this from the home-manager
    # module. This NixOS-level variant exists for hosts without home-manager.
    enable = mkEnableOption "hermes agent (NixOS-level)";
    user = mkOption {
      type = types.str;
      default = "sylvester";
    };
  };

  config = mkIf cfg.enable {
    # Install into the user's NixOS profile (/etc/profiles/per-user/$USER),
    # which puts the packages on that user's PATH only.
    users.users.${cfg.user}.packages = hermesEnv.packages;

    # Per-user login environment. This nixpkgs has no
    # users.users.<name>.sessionVariables, so scope a /etc/profile snippet to
    # the target user instead of setting these for everyone on the box.
    environment.loginShellInit = ''
      if [ "$USER" = '${cfg.user}' ]; then
        export HERMES_TUI="${hermesEnv.sessionVariables.HERMES_TUI}"
        export AGENT_BROWSER_EXECUTABLE_PATH='${hermesEnv.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH}'
      fi
    '';
  };
}
