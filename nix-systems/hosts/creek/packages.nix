{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    alejandra
    git
    git-lfs
    helix
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
}
