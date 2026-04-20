{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.nix;

  devenvSubstituter = "https://devenv.cachix.org";
  devenvKeys = [
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
  ];

  nixCommunitySubstituter = "https://nix-community.cachix.org";
  nixCommunityKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  localSigningKeys = [
    "delta:MfokDZYzRFSHuj8dIQuPVw5GoeFKUvOqJAVjJnxJ2RE="
  ];
in
{
  options.my.nix = {
    devenv-cache.enable = mkEnableOption "devenv cache" // {
      default = true;
    };
    nix-community-cache.enable = mkEnableOption "nix-community cache" // {
      default = true;
    };
  };

  config = {
    nix.settings = {
      substituters =
        (optionals cfg.nix-community-cache.enable [ nixCommunitySubstituter ])
        ++ (optionals cfg.devenv-cache.enable [ devenvSubstituter ]);
      trusted-public-keys = localSigningKeys
        ++ (optionals cfg.nix-community-cache.enable nixCommunityKeys)
        ++ (optionals cfg.devenv-cache.enable devenvKeys);
    };

    sops.templates."nix-access-tokens.conf" = {
      content = ''
        access-tokens = github.com=${config.sops.placeholder."nix-access-tokens/github.com"}
      '';
    };

    nix.extraOptions = ''
      !include ${config.sops.templates."nix-access-tokens.conf".path}
    '';
  };
}
