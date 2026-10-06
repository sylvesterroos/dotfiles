{
  flake.modules.homeManager.base =
    { lib, config, ... }:
    with lib;

    {
      programs.yazi = {
        enable = true;
      }
      // optionalAttrs (config.home.stateVersion < "26.05") {
        shellWrapperName = "y";
      };
    };
}
