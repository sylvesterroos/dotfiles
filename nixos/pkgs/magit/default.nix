{ pkgs, lib, ... }:

let
  magitScript = pkgs.writeTextFile {
    name = "magit.bash";
    text = ''
      #!/usr/bin/env bash

      args=(--no-window-system --no-init-file --load @initEl@)

      if [ "$#" -eq 1 ]; then
        cd "$1" || exit
      fi

      if [ "$#" -eq 2 ]; then
        cd "$1" || exit
        export SHA=$2
      fi

      @emacs@/bin/emacs "''${args[@]}"
    '';
  };

  initEl = ./magit/init.el;

in
pkgs.stdenv.mkDerivation {
  name = "magit";

  buildInputs = [ pkgs.emacs ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    substitute ${magitScript} $out/bin/magit \
      --subst-var-by emacs ${pkgs.emacs} \
      --subst-var-by initEl ${initEl}
    chmod +x $out/bin/magit
  '';
}
