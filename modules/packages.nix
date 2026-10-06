{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        alejandra
        bat
        btop
        bubblewrap
        cachix
        eza
        fzf
        inetutils
        jq
        neovim
        ripgrep
        termscp
        unzip
        wget
      ];
    };
}
