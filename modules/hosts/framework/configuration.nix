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
        netbird
        programming
      ];
      home-manager.users.sylvester.imports = [ config.flake.modules.homeManager.framework ];
    };
  };

  flake.modules.nixos.framework =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.default
        inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
      ];

      networking.hostName = "framework";

      # Framework's minimum kernel for the 13 Pro is 6.19, above tip's default.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.zswap.enable = true;

      # The EC stores the limit; NixOS has no option, so reapply it each boot.
      systemd.services.framework-charge-limit = {
        description = "Set Framework battery charge limit to 80%";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${lib.getExe pkgs.framework-tool} --charge-limit 80";
        };
      };

      users.users.sylvester.extraGroups = [ "plugdev" ];

      # With the lid closed the reader is out of reach: skip pam_fprintd and
      # ask for the password at once.
      security.pam.services.sudo.rules.auth.skip-fprintd-lid-closed = {
        order = config.security.pam.services.sudo.rules.auth.fprintd.order - 10;
        control = "[success=1 default=ignore]";
        modulePath = "${pkgs.linux-pam}/lib/security/pam_exec.so";
        args = [
          "quiet"
          (toString (
            pkgs.writeShellScript "lid-closed" ''
              exec ${pkgs.gnugrep}/bin/grep -qs closed /proc/acpi/button/lid/*/state
            ''
          ))
        ];
      };

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      system.stateVersion = "26.11";
    };
}
