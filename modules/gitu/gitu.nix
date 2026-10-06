{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gitu
      ];

      home.file.".config/gitu/config.toml".source = ./config.toml;
    };
}
