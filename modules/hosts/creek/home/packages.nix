{
  flake.modules.homeManager.creek =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        vesktop
        # newelle
      ];
    };
}
