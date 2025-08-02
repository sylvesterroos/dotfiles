{ ... }:
{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--nogcroots --keep-since 14d";
    };
  };
}
