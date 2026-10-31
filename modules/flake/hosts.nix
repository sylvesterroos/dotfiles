# Turns each `configurations.nixos.<host>` into a NixOS system: the host's
# nixpkgs release, the base role and the host's own module.
{
  config,
  lib,
  ...
}:
let
  mv = config.multiverse;
in
{
  options.configurations.nixos = lib.mkOption {
    description = "The NixOS hosts this flake builds.";
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options = {
          nixpkgs = lib.mkOption {
            type = lib.types.str;
            description = "Multiverse selector of the nixpkgs release the host runs.";
          };
          sshHostKey = lib.mkOption {
            type = lib.types.str;
            description = "The host's ed25519 SSH host public key. Its sops age recipient in .sops.yaml derives from this key.";
          };
          module = lib.mkOption {
            type = lib.types.deferredModule;
            description = "The host: its roles, hardware and host-only settings.";
          };
        };
      }
    );
  };

  config.flake.nixosConfigurations = lib.mapAttrs (
    _: host:
    (mv.flakeAt host.nixpkgs).lib.nixosSystem {
      modules = [
        config.flake.modules.nixos.base
        host.module
      ];
    }
  ) config.configurations.nixos;
}
