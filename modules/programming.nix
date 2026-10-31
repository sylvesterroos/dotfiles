# Development tools for every host that writes code, graphical or not. These
# install through NixOS because bachus runs without home-manager.
{ config, ... }:
let
  mv = config.multiverse;
in
{
  flake.modules.nixos.programming =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        mv.tip.devenv
        nil
      ];
    };
}
