{
  flake.modules.homeManager.base =
    { lib, config, ... }:
    with lib;

    {
      programs.yazi = {
        enable = true;
        settings = {
          mgr.ratio = [
            1
            3
            4
          ];
          preview = {
            max_width = 2000;
            max_height = 2000;
          };
        };
      }
      // optionalAttrs (config.home.stateVersion < "26.05") {
        shellWrapperName = "y";
      };
    };
}
