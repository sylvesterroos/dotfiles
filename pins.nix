# Packages held back or patched ahead of upstream.
# `nu pins.nu` reports which pins can be dropped at the locked inputs.
{
  # Package groups served from an older nixpkgs revision by the `pins`
  # overlay. `broken` names the multiverse selector the packages fail on,
  # tip when absent; a group can be dropped once all its packages build there.
  nixpkgs = {
    zotero = {
      rev = "b1b875982b17";
      packages = [ "zotero" ];
      reason = "zotero 10.0.2+ fails to build against current Firefox";
      upstream = "https://github.com/NixOS/nixpkgs/pull/574462";
    };
    kernel-modules = {
      rev = "fe13242281a6";
      packages = [
        "linuxPackages_zen"
        "aggregateModules"
      ];
      reason = "out-of-tree modules fail to build or merge since kernel.dev gained System.map and module signing";
      upstream = "https://github.com/NixOS/nixpkgs/issues/576406";
    };
    copyparty = {
      rev = "fe13242281a6";
      broken = "26.05";
      packages = [ "copyparty" ];
      reason = "Pillow 13, backported to 26.05, rejects Image.fromarray modes that pillow-jpls and imageio still pass, so both fail their tests";
    };
  };

  # Upstream fixes the `pins` overlay adds to a package, named by its
  # attribute path. A patch can be dropped once the package's source on tip
  # already contains it.
  patches = { };

  # Flake inputs locked to a commit in flake.nix. `broken` is the upstream
  # commit that fails; the pin can go once upstream moves past it and builds.
  inputs = {
    linux-wallpaper-engine = {
      broken = "f52102134ea4205a422eb93cc5550e8568a8d769";
      reason = "electron-forge vite plugin: `vite_1.default.build` undefined";
    };
  };
}
