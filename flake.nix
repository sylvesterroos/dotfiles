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

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

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

    # A release tag; update by moving the tag. Follows its own nixpkgs so
    # hermes-agent.cachix.org serves the build.
    hermes-agent.url = "github:NousResearch/hermes-agent/v0.21.6";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
