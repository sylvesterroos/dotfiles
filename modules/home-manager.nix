# Home-manager runs inside the NixOS evaluation, so one import decision per
# host configures both the system and sylvester's home, and home modules can
# read the system through `osConfig`.
{ config, inputs, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.desktop = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      users.sylvester.imports = [
        hm.base
        hm.desktop
      ];
    };
  };
}
