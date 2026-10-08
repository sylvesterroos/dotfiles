# Select a service's NixOS module and package from one nixpkgs revision.
{
  pkgs,
  name,
  module,
}:
{
  disabledModules = [ module ];
  imports = [ "${pkgs.path}/nixos/modules/${module}" ];
  services.${name}.package = pkgs.${name};
}
