{ inputs, ... }:
{
  flake.modules.nixos.base =
    { config, ... }:
    {
      nix.settings = {
        experimental-features = (import "${inputs.self}/flake.nix").nixConfig.experimental-features;
        auto-optimise-store = true;
        substituters = [
          "https://devenv.cachix.org"
          "https://nix-community.cachix.org"
          "https://hermes-agent.cachix.org"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "delta:MfokDZYzRFSHuj8dIQuPVw5GoeFKUvOqJAVjJnxJ2RE="
          "creek:UcoGc9NgCBfUQMcw+qJimw+sve+YNLn+tNnte1DupMU="
          "framework:xPJF9d9Cr9q/rZK0BThVhcKQHkvT2HtHSF02K5qeHJs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hermes-agent.cachix.org-1:jN3pjR50Mxi4SESKC/FIMNM6/LCosvPk2VUwzVvebzU="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };

      sops.secrets."nix-access-tokens/github.com".sopsFile = "${inputs.self}/secrets/shared.yaml";

      sops.templates."nix-access-tokens.conf".content = ''
        access-tokens = github.com=${config.sops.placeholder."nix-access-tokens/github.com"}
      '';

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens.conf".path}
      '';
    };
}
