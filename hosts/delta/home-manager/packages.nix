{ pkgs, ... }:
{
  home.packages = with pkgs; [
    haruna
    lmstudio
  ];
}
