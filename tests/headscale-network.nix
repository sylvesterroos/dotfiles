# Kernel-level networking test with full root capabilities in a disposable VM.
let
  flake = builtins.getFlake (toString ../.);
  pkgs = flake.nixosConfigurations.creek.pkgs;
  script = pkgs.lib.removeSuffix " up" flake.nixosConfigurations.creek.config.systemd.services.headscale-network.serviceConfig.ExecStart;
in
pkgs.testers.runNixOSTest {
  name = "headscale-network";
  nodes.machine = {
    networking.firewall.trustedInterfaces = [
      "headscale-host"
      "tailscale0"
    ];
    networking.firewall.extraCommands =
      flake.nixosConfigurations.creek.config.networking.firewall.extraCommands;
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    services.resolved = {
      enable = true;
      dnsDelegates = flake.nixosConfigurations.creek.config.services.resolved.dnsDelegates // {
        personal.Delegate = {
          DNS = "100.101.139.30";
          Domains = "~.";
          DefaultRoute = true;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      python3
      nushell
      iproute2
      nftables
      procps
      util-linux
      dnsmasq
    ];
    virtualisation.memorySize = 768;
    virtualisation.cores = 2;
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    output = machine.succeed("NETWORK_SCRIPT=${script} python ${./headscale-network.py}")
    print(output)
  '';
}
