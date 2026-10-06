{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    outputs.homeManagerModules.my

    # ./plasma-settings.nix
    ./packages.nix
    ./prism-launcher.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "sylvester";
    homeDirectory = "/home/sylvester";
  };

  home.sessionVariables = {
    # fuck microsoft
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # programs.vscode = {
  #   enable = true;
  #   package = pkgs.vscode-fhs;
  # };

  programs.command-not-found.enable = false;
  programs.gh.enable = true;
  programs.nix-index.enable = true;
  programs.yt-dlp.enable = true;

  ###
  # My
  ###

  my = {
    bash.alternativeShell = "nu";
    radicle.alias = "sylvesterroos-delta";
    syncthing-client.enable = true;
    attic-client = {
      enable = true;
      token = "attic/tokens/delta";
    };
  };

  home.stateVersion = "25.05";
}
