{ inputs, ... }:
{
  flake.modules.nixos.desktop = {
    imports = [ inputs.bootvine.nixosModules.default ];
    services.bootvine.enable = true;

    nix.settings = {
      substituters = [ "https://wvhulle.cachix.org" ];
      trusted-public-keys = [ "wvhulle.cachix.org-1:heXx8DZMiRsKUx6l1TxNoF+Nmtmz66QEdsonQzc1ir0=" ];
    };
  };
}
