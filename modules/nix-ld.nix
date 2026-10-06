{
  flake.modules.nixos.base = {
    # Run unpatched dynamic binaries on NixOS
    programs.nix-ld = {
      enable = true;
    };
  };
}
