{
  self,
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.determinate.darwinModules.default
  ];

  # Disable nix-darwin management of daemon
  nix.enable = false;

  determinate-nix.customSettings = {
    extra-substituters = "https://devenv.cachix.org";
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];
    config = {allowUnfree = true;};
  };

  users.users.sylvester = {
    home = "/Users/sylvester";
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
  };
  programs.fish.enable = true;

  # environment.systemPackages = with pkgs; [
  # ];

  # users.users.sylvester.packages = with pkgs; [
  # ];

  environment.variables = {
    NH_DARWIN_FLAKE = "$HOME/.dotfiles/nix-systems";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.primaryUser = "sylvester";
  system.defaults.NSGlobalDomain.NSScrollAnimationEnabled = false;

  security.pam.services.sudo_local.touchIdAuth = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
