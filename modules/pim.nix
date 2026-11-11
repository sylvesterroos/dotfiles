# The personal information management tools for Hermes: mail, calendar and contacts read through the
# Proton command line. Every host plays Hermes, so every host adds them.
{ config, inputs, ... }:
let
  mv = config.multiverse;
in
{
  flake.modules.nixos.base = {
    my.hermes-agent.plugins = [ "${inputs.self}/pkgs/hermes-plugin-pim" ];
    environment.systemPackages = [ mv.tip.proton-cli ];
  };
}
