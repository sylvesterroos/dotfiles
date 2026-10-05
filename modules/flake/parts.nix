{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.treefmt-nix.flakeModule
  ];

  # aarch64-darwin: pkgs/mpatch carries darwin build logic.
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  # The one multiverse instance every host and user resolves packages from, so
  # a selector means the same package set everywhere.
  _module.args.mv = inputs.multiverse.lib.mkMultiverse {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
}
