{ ... }:
{
  enable = true;
  shellAliases = {
    ls = "eza -alg --color=always --group-directories-first --header";

    cat = "bat -pp"; # no line numbers, no pager

    ssh-keygen-ed25519 = "ssh-keygen -t ed25519 -C (whoami)@(uname -n)";
  };
  interactiveShellInit = ''
    alias :q="exit"
  '';
  shellAbbrs = {
    update = "nix flake update $HOME/.dotfiles/system";
    rebuild = "sudo nixos-rebuild --flake path:$HOME/.dotfiles/system#odysseus";

    nsh = "nix-shell --run fish";
    # nshu = "nix-shell --run fish -I nixpkgs=channel:nixpkgs-unstable";

    yta-best = "yt-dlp --add-metadata --extract-audio --audio-format best";
    ytv-best = "yt-dlp --add-metadata -f bestvideo+bestaudio";
  };
}
