{
  inputs,
  outputs,
  lib,
  config,
  osConfig,
  pkgs,
  ...
}: {
  imports = [
    # ./plasma.nix
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

  programs.home-manager.enable = true;

  home = {
    username = "sylvester";
    homeDirectory = "/home/sylvester";
  };

  home.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    # fuck microsoft
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  };

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
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

  programs.gh.enable = true;
  programs.starship.enable = true;
  programs.autojump.enable = true;
  programs.yt-dlp.enable = true;
  programs.yazi.enable = true;
  programs.zed-editor.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}
