# Install medium for the framework: the minimal ISO on the newest kernel, with
# bcachefs added so disko can format the disk. Built from the framework's own
# nixpkgs release, so its kernel and bcachefs module match the installed ones.
{ config, ... }:
let
  mv = config.multiverse;
  installer = (mv.flakeAt config.configurations.nixos.framework.nixpkgs).lib.nixosSystem {
    modules = [
      (
        { modulesPath, ... }:
        {
          imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix" ];
          nixpkgs.hostPlatform = "x86_64-linux";
          boot.supportedFilesystems.bcachefs = true;
        }
      )
    ];
  };
in
{
  flake.packages.x86_64-linux.framework-installer = installer.config.system.build.isoImage;
}
