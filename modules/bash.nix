{
  flake.modules.homeManager.base =
    { pkgs, lib, ... }:
    {
      programs.bash = {
        enable = true;

        initExtra = (
          lib.mkAfter ''
            if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "nu" && -z ''${BASH_EXECUTION_STRING} ]]
            then
              shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
              exec ${pkgs.nushell}/bin/nu $LOGIN_OPTION
            fi
          ''
        );
      };
    };
}
