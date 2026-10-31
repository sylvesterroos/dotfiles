# The roles a host composes from. Feature files add to them; a host imports
# the roles it plays: every host `base`, plus any of `desktop` (a graphical
# session) and `programming`. Roles never import each other: the module
# system merges them, so a host's import list is its whole composition.
{
  flake.modules = {
    nixos.base = { };
    nixos.desktop = { };
    nixos.programming = { };
    homeManager.base = { };
    homeManager.desktop = { };
  };
}
