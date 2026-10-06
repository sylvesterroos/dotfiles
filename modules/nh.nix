{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          dates = "daily";
          extraArgs = "--nogcroots --keep-since 14d";
        };
        flake = lib.mkDefault "/home/sylvester/.dotfiles";
      };
    };
}
