# Evaluate a service replacement against the chosen NixOS base.
{ base, pkgs }:
let
  serviceFrom = import ../lib/service-from.nix;
  system = base.lib.nixosSystem {
    system = pkgs.stdenv.hostPlatform.system;
    modules = [
      (serviceFrom {
        inherit pkgs;
        name = "immich";
        module = "services/web-apps/immich.nix";
      })
      {
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "/dev/test-root";
          fsType = "ext4";
        };
        system.stateVersion = "26.05";
        services.immich = {
          enable = true;
          port = 2284;
          machine-learning.enable = false;
          secretsFile = "/run/secrets/immich-test";
          database = {
            host = "127.0.0.1";
            port = 5431;
          };
        };
        services.postgresql.settings.port = 5431;
      }
    ];
  };
  cfg = system.config;
  unit = cfg.systemd.services.immich-server;
  moduleFile = "${pkgs.path}/nixos/modules/services/web-apps/immich.nix";
in
assert cfg.services.immich.package.drvPath == pkgs.immich.drvPath;
assert builtins.elem moduleFile system.options.services.immich.enable.declarations;
assert unit.serviceConfig.ExecStart == pkgs.lib.getExe pkgs.immich;
assert unit.environment.IMMICH_PORT == "2284";
assert unit.environment.DB_HOSTNAME == "127.0.0.1";
assert unit.environment.DB_PORT == "5431";
{
  hostVersion = cfg.system.nixos.release;
  packageVersion = cfg.services.immich.package.version;
  module = moduleFile;
  execStart = unit.serviceConfig.ExecStart;
  toplevel = cfg.system.build.toplevel.drvPath;
}
