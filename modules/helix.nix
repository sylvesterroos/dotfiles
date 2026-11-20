{
  flake.modules.homeManager.base =
    { config, lib, ... }:
    {
      programs.helix.enable = true;
      home.sessionVariables.EDITOR = lib.getExe config.programs.helix.package;
    };

  flake.modules.nixos.without-home-manager =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.helix ];
      environment.variables.EDITOR = lib.getExe pkgs.helix;
    };
}
