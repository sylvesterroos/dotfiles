{
  lib,
  path,
  inputs ? {},
  outputs ? {},
}: let
  files = lib.attrNames (lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".nix" name)
    (builtins.readDir path));

  modules =
    map (
      file:
        import (path + "/${file}")
    )
    files;
in
  modules
