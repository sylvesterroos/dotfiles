# Replace with `nixos-generate-config --no-filesystems --show-hardware-config`
# from the installer; disko owns the file systems.
{
  flake.modules.nixos.framework = {
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
