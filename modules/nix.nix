{
  flake.modules.nixos.base =
    { config, ... }:
    {
      nix.settings = {
        auto-optimise-store = true;
        substituters = [
          "https://devenv.cachix.org"
          "https://nix-community.cachix.org"
          "https://hermes-agent.cachix.org"
        ];
        trusted-public-keys = [
          "delta:MfokDZYzRFSHuj8dIQuPVw5GoeFKUvOqJAVjJnxJ2RE="
          "creek:UcoGc9NgCBfUQMcw+qJimw+sve+YNLn+tNnte1DupMU="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hermes-agent.cachix.org-1:jN3pjR50Mxi4SESKC/FIMNM6/LCosvPk2VUwzVvebzU="
        ];
      };

      sops.templates."nix-access-tokens.conf".content = ''
        access-tokens = github.com=${config.sops.placeholder."nix-access-tokens/github.com"}
      '';

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens.conf".path}
      '';
    };
}
