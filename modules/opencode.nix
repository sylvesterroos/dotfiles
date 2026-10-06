{
  flake.modules.homeManager.base = {
    programs.opencode = {
      enable = true;

      settings = {
        plugin = [ "opencode-handoff" ];
      };
    };
  };
}
