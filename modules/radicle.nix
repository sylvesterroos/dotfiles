{
  flake.modules.homeManager.base =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    {
      warnings = [
        "Radicle private repositories are insecure: node traffic is neither encrypted nor authenticated. Use public repositories only."
      ];

      home.packages =
        with pkgs;
        [ ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          radicle-desktop
        ];

      programs.radicle = {
        enable = true;
        settings.node.alias = "sylvesterroos-${osConfig.networking.hostName}";
      };

      services.radicle.node = {
        enable = true;
        lazy.enable = true;
      };
    };
}
