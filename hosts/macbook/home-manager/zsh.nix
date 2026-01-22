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
          if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' && -z "''${ZSH_EXECUTION_STRING+x}" ]]
          then
              exec fish -l
          fi
        '';
      in
      lib.mkMerge [ zshConfigLastInit ];
  };
}
