# sylvester's home and the everyday CLI programs every workstation carries.
{
  flake.modules.homeManager.desktop = {
    home = {
      username = "sylvester";
      homeDirectory = "/home/sylvester";
    };

    programs.home-manager.enable = true;

    # https://learn.microsoft.com/en-us/dotnet/core/tools/telemetry
    home.sessionVariables.DOTNET_CLI_TELEMETRY_OPTOUT = "1";

    programs.command-not-found.enable = false;
    programs.nix-index.enable = true;

    programs.tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.gh.enable = true;
    programs.yt-dlp.enable = true;
  };
}
