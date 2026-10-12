{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.treefmt-nix.flakeModule
  ];

  options = {
    multiverse = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      description = "The shared Multiverse instance used to select package sets.";
    };
    serviceFrom = lib.mkOption {
      type = lib.types.functionTo lib.types.deferredModule;
      readOnly = true;
      description = "Select a service's NixOS module and package from one package set.";
    };
  };

  # aarch64-darwin: pkgs/mpatch carries darwin build logic.
  config.systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  config.serviceFrom = import "${inputs.self}/lib/service-from.nix";

  # The one multiverse instance every host and user resolves packages from, so
  # a selector means the same package set everywhere.
  config.multiverse = inputs.multiverse.lib.mkMultiverse {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
}
