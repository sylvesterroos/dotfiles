{ config, inputs, ... }:
let
  mv = config.multiverse;
  hosts = config.configurations.nixos;
  herdrTui = mv.tip.herdr;
in
{
  flake.modules.nixos.bachus = {
    users.users.sylvester.packages = [ herdrTui ];
  };

  flake.modules.homeManager.desktop =
    { osConfig, pkgs, ... }:
    let
      # The GUI loads the host's Mesa into its own process, and Mesa needs the
      # glibc it was built with. Build upstream's flake against the nixpkgs
      # this host runs instead of the nixpkgs its input follows.
      herdrGui = (import "${inputs.herdr-gpui}/flake.nix").outputs (
        inputs.herdr-gpui.inputs
        // {
          self = inputs.herdr-gpui;
          nixpkgs = mv.flakeAt hosts.${osConfig.networking.hostName}.nixpkgs;
        }
      );
    in
    {
      home.packages = [
        herdrTui
        herdrGui.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
