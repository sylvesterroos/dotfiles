# Temporary bridge: builds the hosts from the pre-dendritic files under
# legacy/ and hosts/. Shrinks as features move into modules/; deleted at the end.
{
  config,
  inputs,
  mv,
  ...
}:
let
  inherit (inputs) self;
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
    selector: extra: host: roles:
    (mv.flakeAt selector).lib.nixosSystem {
      inherit system;
      specialArgs = specialArgs // extra;
      modules = [
        ../../hosts/${host}/configuration.nix
        config.flake.modules.nixos.base
      ]
      ++ roles;
    };

  desktop = host: [
    config.flake.modules.nixos.desktop
    {
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.users.sylvester.imports = [ ../../hosts/${host}/home-manager/home.nix ];
    }
  ];
in
{
  flake = {
    nixosConfigurations = {
      creek = nixos "tip" { } "creek" (desktop "creek");
      delta = nixos "tip" { } "delta" (desktop "delta" ++ [ config.flake.modules.nixos.livebook ]);
      bachus = nixos latestStable { inherit patchedNixpkgsStable; } "bachus" [
        config.flake.modules.nixos.without-home-manager
        config.flake.modules.nixos.attic-server
      ];
    };
  };
}
