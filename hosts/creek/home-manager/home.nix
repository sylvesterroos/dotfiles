{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    outputs.homeManagerModules.my

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./packages.nix
  ];

  home = {
    username = "sylvester";
    homeDirectory = "/home/sylvester";
  };

  # Add stuff for your user as you see fit:
  home.sessionVariables = {
    # fuck microsoft
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  };
  systemd.user.sessionVariables = {
    # macos-like font rendering
    # https://blog.aktsbot.in/no-more-blurry-fonts.html
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  programs.home-manager.enable = true;

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

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
  };

  programs.gh.enable = true;
  programs.yt-dlp.enable = true;

  ###
  # My
  ###

  my = {
    bash.alternativeShell = "nu";
    radicle.alias = "sylvesterroos-creek";
    syncthing-client.enable = true;
  };

  home.stateVersion = "23.05";
}
