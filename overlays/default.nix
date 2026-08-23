# This file defines overlays
{ inputs, ... }:
let
  patchedNixpkgsStableFor =
    system: nixpkgs:
    (import nixpkgs { inherit system; }).applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [
        ./patches/immich-postgres-unix-socket-port.patch
      ];
    };

in
{
  # TODO: remove once PR is merged
  # https://github.com/NixOS/nixpkgs/pull/481056
  patched-nixpkgs-stable = patchedNixpkgsStableFor;

  additions =
    final: prev:
    {
      nix-alien = inputs.nix-alien.packages.${prev.stdenv.hostPlatform.system}.default;
    }
    # This one brings our custom packages from the 'pkgs' directory
    // (import ../pkgs final.pkgs);

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # KDE apps get a single merged XDG_DATA_DIRS instead of dozens of duplicated
  # per-package share dirs injected by the qt wrapper hook.
  # https://github.com/NixOS/nixpkgs/issues/126590#issuecomment-3194531220
  # https://github.com/NixOS/nixpkgs/issues/126590#issuecomment-3694376547
  # https://github.com/NixOS/nixpkgs/issues/126590#issuecomment-3741634437
  kde-xdg-data-dirs = final: prev: {
    kdePackages = prev.kdePackages.overrideScope (
      kdeFinal: kdePrev: {
        plasma-workspace =
          let
            # the package we want to override
            basePkg = kdePrev.plasma-workspace;

            # a helper package that merges all the XDG_DATA_DIRS into a single
            # directory; symlinks instead of copies to save space and build I/O
            xdgdataPkg = final.stdenv.mkDerivation {
              name = "${basePkg.name}-xdgdata";
              buildInputs = [ basePkg ];
              dontUnpack = true;
              dontFixup = true;
              dontWrapQtApps = true;
              installPhase = ''
                mkdir -p $out/share
                ( IFS=:
                  for DIR in $XDG_DATA_DIRS; do
                    if [[ -d "$DIR" ]]; then
                      ${prev.lib.getExe prev.lndir} -silent "$DIR" $out/share
                    fi
                  done
                )
              '';
            };

            # undo the XDG_DATA_DIRS injection that is usually done in the qt
            # wrapper script and instead inject the path of the above helper
            derivedPkg = basePkg.overrideAttrs {
              preFixup = ''
                for index in "''${!qtWrapperArgs[@]}"; do
                  if [[ ''${qtWrapperArgs[$((index+0))]} == "--prefix" ]] && [[ ''${qtWrapperArgs[$((index+1))]} == "XDG_DATA_DIRS" ]]; then
                    unset -v "qtWrapperArgs[$((index+0))]"
                    unset -v "qtWrapperArgs[$((index+1))]"
                    unset -v "qtWrapperArgs[$((index+2))]"
                    unset -v "qtWrapperArgs[$((index+3))]"
                  fi
                done
                qtWrapperArgs=("''${qtWrapperArgs[@]}")
                qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "${xdgdataPkg}/share")
                qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "$out/share")
              '';
            };
          in
          derivedPkg;
      }
    );
  };
}
