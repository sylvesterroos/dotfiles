{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.bash;
in {
  options.my.bash = {
    enable =
      mkEnableOption "bash-shell"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;

      initExtra = let
        bashConfig = lib.mkAfter ''
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';
      in
        lib.mkMerge [
          (lib.mkIf config.my.fish.enable bashConfig)
        ];
    };
  };
}
