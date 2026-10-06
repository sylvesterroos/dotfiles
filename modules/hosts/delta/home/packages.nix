{
  flake.modules.homeManager.delta =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        lmstudio
      ];
    };
}
