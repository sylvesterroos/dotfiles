{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.nixos-packages;
in {
  options.my.nixos-packages = {
    enable =
      mkEnableOption "nixos-packages"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      alejandra
      neovim
      wget
      eza
      ripgrep
      unzip
      logiops
      btop
      bat
      morewaita-icon-theme
      termscp
      jq
      inetutils
      fzf
    ];
  };
}
