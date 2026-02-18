{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.bash;

  shellCommands = {
    fish = "${pkgs.fish}/bin/fish";
    nu = "${pkgs.nushell}/bin/nu";
  };
in
{
  options.my.bash = {
    enable = mkEnableOption "bash-shell" // {
      default = true;
    };

    alternativeShell = mkOption {
      type = types.nullOr (types.enum (builtins.attrNames shellCommands));
      default = null;
      description = "Alternative shell to exec into from bash (e.g. \"fish\" or \"nu\").";
    };
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;

      initExtra = mkIf (cfg.alternativeShell != null) (lib.mkAfter ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "${cfg.alternativeShell}" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${shellCommands.${cfg.alternativeShell}} $LOGIN_OPTION
        fi
      '');
    };
  };
}
