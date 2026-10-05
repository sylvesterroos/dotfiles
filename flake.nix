{
  nixConfig = {
    experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];

    flake-registry = "";
  };

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    multiverse.url = "github:fzakaria/nixpkgs-multiverse";

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sylvesterroos-com = {
      url = "git+https://github.com/sylvesterroos/sylvesterroos.com";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-flatpak.url = "https://flakehub.com/f/gmodena/nix-flatpak/0.*";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # Pinned; see pins.nix.
    linux-wallpaper-engine.url = "github:jagrat7/linux-wallpaper-engine/27cb7f959a1ca1221526b3b436deeffa6c3a683b";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copyparty = {
      url = "github:9001/copyparty";
      # upstream's input is broken
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ublock = {
      url = "github:imputnet/uBlock";
      flake = false;
    };

    cua.url = "github:trycua/cua";
  };

  outputs =
    {
      self,
      nixpkgs,
      multiverse,
      home-manager,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      # Our own multiverse instance so revisions evaluate with the same
      # allowUnfree the old stable/unstable overlay imports used.
      mv = multiverse.lib.mkMultiverse {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      # Newest stable release the multiverse index knows; advances on its own
      # when a release branches.
      latestStable = nixpkgs.lib.last mv.releases;
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # treefmt config from ./treefmt.nix, evaluated per system
      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      # Multi-language formatter (treefmt), available through 'nix fmt'
      # Formats nix, json, yaml, toml and nu files; config in ./treefmt.nix
      # Formatting check runs on 'nix flake check' (checks.<system>.formatting)
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Verify the whole tree is formatted, runs on 'nix flake check'
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs mv; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations = {
        creek = (mv.flakeAt "tip").lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              outputs
              system
              mv
              ;
          };
          modules = [
            ./hosts/creek/configuration.nix
          ];
        };

        delta = (mv.flakeAt "tip").lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              outputs
              system
              mv
              ;
          };
          modules = [
            ./hosts/delta/configuration.nix
          ];
        };

        bachus = (mv.flakeAt latestStable).lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              outputs
              system
              mv
              ;
            # TODO: remove once PR is merged
            # https://github.com/NixOS/nixpkgs/pull/481056
            patchedNixpkgsStable = outputs.overlays.patched-nixpkgs-stable system (mv.flakeAt latestStable);
          };
          modules = [
            ./hosts/bachus/configuration.nix
          ];
        };
      };

      homeConfigurations = {
        "sylvester@creek" =
          let
            system = "x86_64-linux";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = mv.tip;
            extraSpecialArgs = {
              inherit
                inputs
                outputs
                system
                mv
                ;
            };
            modules = [
              ./hosts/creek/home-manager/home.nix
            ];
          };

        "sylvester@delta" =
          let
            system = "x86_64-linux";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = mv.tip;
            extraSpecialArgs = {
              inherit
                inputs
                outputs
                system
                mv
                ;
            };
            modules = [
              ./hosts/delta/home-manager/home.nix
            ];
          };

      };
    };
}
