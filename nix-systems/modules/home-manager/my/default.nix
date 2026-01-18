let
  dir = ./.;
  entries = builtins.readDir dir;
  nixFiles = builtins.filter (
    f: f != "default.nix" && builtins.match ".*\\.nix" f != null
  ) (builtins.attrNames entries);
  subdirsWithDefault = builtins.filter (
    name:
    entries.${name} == "directory"
    && builtins.pathExists (dir + "/${name}/default.nix")
  ) (builtins.attrNames entries);
  autoImports =
    builtins.map (f: dir + "/${f}") nixFiles
    ++ builtins.map (d: dir + "/${d}") subdirsWithDefault;
in
{
  imports = autoImports;
}
