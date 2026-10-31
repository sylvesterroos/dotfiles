# Framework: Framework Laptop 13 Pro, Intel Core Ultra X7 358H. Starts from
# stock nixpkgs plus nixos-hardware's Framework module.
{
  config,
  inputs,
  ...
}:
{
  configurations.nixos.framework = {
    nixpkgs = "tip";
    sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMVMKMM7bqPyi8ryo4TGfDwxRkSG+fVfWf0HjdYS8S61";
    nixSigningKey = "framework:xPJF9d9Cr9q/rZK0BThVhcKQHkvT2HtHSF02K5qeHJs=";
    module = {
      imports = with config.flake.modules.nixos; [
        gaming
        desktop
        framework
        headscaled
        programming
      ];
      home-manager.users.sylvester.imports = [ config.flake.modules.homeManager.framework ];
    };
  };

  flake.modules.nixos.framework =
    { pkgs, ... }:
    {
      imports = [
        inputs.disko.nixosModules.default
        inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
      ];

      networking.hostName = "framework";

      # Framework's minimum kernel for the 13 Pro is 6.19, above tip's default.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.zswap.enable = true;

      my.headscaled.network = config.headscaleNetwork;

      users.users.sylvester.extraGroups = [ "plugdev" ];

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      system.stateVersion = "26.11";
    };
}
