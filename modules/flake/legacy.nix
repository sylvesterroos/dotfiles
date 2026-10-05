# Temporary bridge: builds the hosts from the pre-dendritic files under
# legacy/ and hosts/. Shrinks as features move into modules/; deleted at the end.
{ inputs, mv, ... }:
let
  inherit (inputs) self home-manager;
  system = "x86_64-linux";
  latestStable = inputs.nixpkgs.lib.last mv.releases;
  specialArgs = {
    inherit inputs mv system;
    outputs = self // {
      nixosModules.my = import ../../legacy/nixos/my;
      homeManagerModules.my = import ../../legacy/home-manager/my;
    };
  };

  # TODO: remove once https://github.com/NixOS/nixpkgs/pull/481056 is merged
  patchedNixpkgsStable =
    let
      nixpkgs = mv.flakeAt latestStable;
    in
    (import nixpkgs { inherit system; }).applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [ ../../overlays/patches/immich-postgres-unix-socket-port.patch ];
    };

  nixos =
    selector: extra: host:
    (mv.flakeAt selector).lib.nixosSystem {
      inherit system;
      specialArgs = specialArgs // extra;
      modules = [ ../../hosts/${host}/configuration.nix ];
    };

  home =
    host:
    home-manager.lib.homeManagerConfiguration {
      pkgs = mv.tip;
      extraSpecialArgs = specialArgs;
      modules = [ ../../hosts/${host}/home-manager/home.nix ];
    };
in
{
  flake = {
    nixosConfigurations = {
      creek = nixos "tip" { } "creek";
      delta = nixos "tip" { } "delta";
      bachus = nixos latestStable { inherit patchedNixpkgsStable; } "bachus";
    };

    homeConfigurations = {
      "sylvester@creek" = home "creek";
      "sylvester@delta" = home "delta";
    };
  };
}
