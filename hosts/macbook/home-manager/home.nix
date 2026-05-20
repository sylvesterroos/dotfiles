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
    inputs.open-design.homeManagerModules.default

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
    discord.enable = false;
    linux-wallpaperengine.enable = false;
    llm.enable = false;
    radicle.alias = "sylvesterroos-mac";
    syncthing-client.enable = true;
    zed-editor.enable = false;
  };

  services.open-design = {
    enable = true;
    autoStart = true;
    webFrontend.enable = true;
    # Caddy infers HTTPS for non-standard ports unless the site address
    # carries an explicit scheme; upstream's Caddyfile template is
    # `${host}:${port}`, so we smuggle the scheme through `host`. That
    # bypasses the module's loopback check, so also declare the origin
    # explicitly to satisfy the assertion + CSRF gate.
    # https://github.com/nexu-io/open-design/blob/main/nix/home-manager.nix
    webFrontend.host = "http://127.0.0.1";
    webFrontend.allowedOrigins = [ "http://127.0.0.1:5174" ];
    # TODO: drop overrides once upstream supports aarch64-darwin:
    #   - pnpmDepsHash differs on darwin (same lockfile, both packages)
    #   - better-sqlite3 native build needs cctools (libtool) on darwin
    # https://github.com/nexu-io/open-design/blob/main/nix/package-daemon.nix
    package = inputs.open-design.packages.${pkgs.system}.default.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.cctools ];
      pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
        outputHash = "sha256-TI7gjjF47YIkLblWjG9flG3E1mg310AI5S4uZ+9B2kI=";
      });
    });
    webFrontend.package = inputs.open-design.packages.${pkgs.system}.web.overrideAttrs (old: {
      pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
        outputHash = "sha256-TI7gjjF47YIkLblWjG9flG3E1mg310AI5S4uZ+9B2kI=";
      });
    });
  };

  home.stateVersion = "25.11";
}
