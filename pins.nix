# Packages held back or patched ahead of upstream.
# `nu update.nu` updates the lock and reports which pins can be dropped.
{
  # Package groups served from an older nixpkgs revision by the `pins`
  # overlay. A group can be dropped once all its packages build on tip.
  nixpkgs = {
    zotero = {
      rev = "b1b875982b17";
      packages = [ "zotero" ];
      reason = "zotero 10.0.2+ fails to build against current Firefox";
      upstream = "https://github.com/NixOS/nixpkgs/pull/569006";
    };
  };

  # Upstream fixes the `pins` overlay adds to a package, named by its
  # attribute path. A patch can be dropped once the package's source on tip
  # already contains it.
  patches = {
    nix-output-monitor-unknown-types = {
      package = [ "nix-output-monitor" ];
      patch = ./patches/nix-output-monitor-321.patch;
      reason = "nom 2.2.0 throws ParseNixJSONMessageError on Determinate Nix 3.23's activity and result types";
      upstream = "https://github.com/maralorn/nix-output-monitor/pull/321";
    };
  };

  # Flake inputs locked to a commit in flake.nix. `broken` is the upstream
  # commit that fails; the pin can go once upstream moves past it and builds.
  inputs = {
    linux-wallpaper-engine = {
      broken = "1166a1a29aa2fae79561abf329793c03529534f5";
      reason = "electron-forge vite plugin: `vite_1.default.build` undefined";
    };
  };
}
