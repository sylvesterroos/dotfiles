{
  flake.modules.homeManager.base = {
    programs.neovim = {
      enable = true;
      withPython3 = false;
      withRuby = false;
    };
  };
}
