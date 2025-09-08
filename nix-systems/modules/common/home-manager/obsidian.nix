{pkgs, ...}: {
  programs.obsidian = {
    # Enabling this overwrites ad-hoc settings
    # The module is only useful when configuring Obsidian using Nix as well
    enable = false;
  };

  home.packages = with pkgs; [obsidian];
}
