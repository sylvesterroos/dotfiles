{
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;

    initContent = let
      zshConfigLastInit = lib.mkAfter ''
        export PATH="$PATH:/Users/sylvester/.lmstudio/bin"

        if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
        then
            exec fish -l
        fi
      '';
    in
      lib.mkMerge [zshConfigLastInit];
  };
}
