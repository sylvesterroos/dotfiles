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

  ###
  # My
  ###

  my = {
    bash.enable = false;
    llm.enable = false;
    zed-editor.enable = false;
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
    mcp_proxy_rust
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

  programs.autojump.enable = true;
  programs.gh.enable = true;
  programs.gpg.enable = true;
  programs.mise.enable = true;
  programs.starship.enable = true;
  programs.yazi.enable = true;

  home.stateVersion = "25.11";
}
