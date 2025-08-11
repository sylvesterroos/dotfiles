{pkgs, ...}: {
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
}
