{ inputs, ... }:
{
  flake.modules.nixos.desktop.users.users.sylvester.extraGroups = [ "kvm" ];

  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
        # Cowork's VM runs qemu from the host PATH; the package ships only the firmware and virtiofsd.
        pkgs.qemu_kvm
      ];
    };
}
