# The roles a host composes from. Feature files add to them; a host imports
# the roles it plays: every host `base`, workstations `desktop` as well.
{
  flake.modules = {
    nixos.base = { };
    nixos.desktop = { };
    homeManager.base = { };
    homeManager.desktop = { };
  };
}
