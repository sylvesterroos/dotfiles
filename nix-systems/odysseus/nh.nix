{ ... }:
{
  programs.nh = {
    enable = true;
    flake = "/home/sylvester/.dotfiles/system";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--nogcroots --keep-since 14d";
    };
  };
}
