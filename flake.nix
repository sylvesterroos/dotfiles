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
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    watt = {
      url = "github:NotAShelf/watt";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    sylvesterroos-com = {
      url = "github:sylvesterroos/sylvesterroos.com";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-flatpak.url = "https://flakehub.com/f/gmodena/nix-flatpak/0.*";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    linux-wallpaper-engine.url = "github:jagrat7/linux-wallpaper-engine";

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ublock = {
      url = "github:imputnet/uBlock";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs-unstable.lib.genAttrs systems;
    in
    {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system: import ./pkgs nixpkgs-unstable.legacyPackages.${system});
      # Formatter for your nix files, available through 'nix fmt'
      # To format all Nix files:
      # git ls-files -z '*.nix' | xargs -0 -r nix fmt
      # To check formatting:
      # git ls-files -z '*.nix' | xargs -0 -r nix develop --command nixfmt --check
      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations = {
        creek = nixpkgs-unstable.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs system; };
          modules = [
            ./hosts/creek/configuration.nix
          ];
        };

        delta = nixpkgs-unstable.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs system; };
          modules = [
            ./hosts/delta/configuration.nix
          ];
        };

        bachus = nixpkgs-stable.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs outputs system;
            # TODO: remove once PR is merged
            # https://github.com/NixOS/nixpkgs/pull/481056
            patchedNixpkgsStable = outputs.overlays.patched-nixpkgs-stable system nixpkgs-stable;
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
            pkgs = nixpkgs-unstable.legacyPackages.${system};
            extraSpecialArgs = { inherit inputs outputs system; };
            modules = [
              ./hosts/creek/home-manager/home.nix
            ];
          };

        "sylvester@delta" =
          let
            system = "x86_64-linux";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs-unstable.legacyPackages.${system};
            extraSpecialArgs = { inherit inputs outputs system; };
            modules = [
              ./hosts/delta/home-manager/home.nix
            ];
          };

        "sylvester@Sylvesters-MacBook-Pro" =
          let
            system = "aarch64-darwin";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs-unstable.legacyPackages.${system};
            extraSpecialArgs = { inherit inputs outputs system; };
            modules = [
              ./hosts/macbook/home-manager/home.nix
            ];
          };
      };

      darwinConfigurations."Sylvesters-MacBook-Pro" = nix-darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        specialArgs = {
          inherit
            self
            inputs
            outputs
            system
            ;
        };
        modules = [
          ./hosts/macbook/configuration.nix
        ];
      };
    };
}
