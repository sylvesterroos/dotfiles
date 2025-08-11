{
  lib,
  inputs,
  outputs,
  path,
  extraArgs ? {},
}: let
  files = lib.attrNames (lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".nix" name)
    (builtins.readDir path));

  modules =
    map (
      file: {
        config,
        pkgs,
        ...
      } @ args:
        import (path + "/${file}") (args // extraArgs)
    )
    files;
in
  modules
