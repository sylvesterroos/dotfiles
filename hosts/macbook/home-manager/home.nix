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
    ./git.nix
    ./zsh.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  home.username = "sylvester";
  home.homeDirectory = "/Users/sylvester";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    nh
    eza
    bat
    ripgrep
    prettier # for javascript projects
  ];

  home.sessionVariables = {
    EDITOR = lib.getExe pkgs.neovim;
    VISUAL = "zed";
  };

  #programs.command-not-found.enable = false;
  #programs.nix-index.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.gh.enable = true;
  programs.gpg.enable = true;
  programs.mise.enable = true;

  ###
  # My
  ###

  my = {
    bash.enable = false;
    linux-wallpaperengine.enable = false;
    llm.enable = false;
    radicle.alias = "sylvesterroos-mac";
    syncthing-client.enable = true;
    zed-editor.enable = false;
  };

  home.stateVersion = "25.11";
}
