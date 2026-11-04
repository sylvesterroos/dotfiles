# The librarian tools for Hermes: reads of cached remote git repositories at
# any branch, tag or commit. Every host plays Hermes, so every host adds them.
{ inputs, ... }:
{
  flake.modules.nixos.base.my.hermes-agent.plugins = [
    "${inputs.self}/pkgs/hermes-plugin-librarian"
  ];
}
