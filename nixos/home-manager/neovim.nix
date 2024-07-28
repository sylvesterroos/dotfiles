{ pkgs, ... }:
{
  enable = true;
  package = pkgs.neovim-unwrapped;
  extraPackages = with pkgs; [
    cargo # dependencies built with rust
    gcc # telescope, luasnip
    go # golsp
    ripgrep # telescope
    fd # telescope
    fzf # telescope
    nodePackages_latest.nodejs # copilot
    markdownlint-cli # markdown
    typescript # tsserver
    nodePackages.typescript-language-server # tsserver
  ];
}
