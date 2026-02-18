{
  pkgs,
  lib,
  ...
}:
{
  programs.zsh = {
    enable = true;

    initContent =
      let
        zshConfigLastInit = lib.mkAfter ''
          export PATH="$PATH:/Users/sylvester/.lmstudio/bin"

          # TODO: Remove the final condition when zed#35759 is fixed:
          # https://github.com/zed-industries/zed/issues/35759
          if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'nu' && -z "''${ZSH_EXECUTION_STRING+x}" ]]
          then
              [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=""
              exec ${pkgs.nushell}/bin/nu $LOGIN_OPTION
          fi
        '';
      in
      lib.mkMerge [ zshConfigLastInit ];
  };
}
