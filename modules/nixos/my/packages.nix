{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.nixos-packages;
in
{
  options.my.nixos-packages = {
    enable = mkEnableOption "nixos-packages" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      alejandra
      bat
      btop
      eza
      fzf
      inetutils
      jq
      logiops
      morewaita-icon-theme
      neovim
      ripgrep
      termscp
      unzip
      wget
    ];
  };
}
