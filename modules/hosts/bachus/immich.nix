{ lib, mv, ... }:
let
  # TODO: remove once https://github.com/NixOS/nixpkgs/pull/481056 is merged
  nixpkgs = mv.flakeAt (lib.last mv.releases);
  patched = (import nixpkgs { system = "x86_64-linux"; }).applyPatches {
    name = "nixpkgs-patched";
    src = nixpkgs;
    patches = [ ../../../overlays/patches/immich-postgres-unix-socket-port.patch ];
  };
in
{
  flake.modules.nixos.bachus =
    { ... }:
    {
      disabledModules = [ "services/web-apps/immich.nix" ];
      imports = [
        "${patched}/nixos/modules/services/web-apps/immich.nix"
      ];

      services.immich = {
        enable = true;
        package = mv.tip.immich;
        mediaLocation = "/srv/media/immich";
        host = "0.0.0.0";
        environment = {
          IMMICH_LOG_LEVEL = "verbose";
        };
        database.port = 5431;
        machine-learning.enable = false;
      };
      # Tailnet-only via tailnet-services.nix; the port stays firewalled.
    };
}
