{ pkgs }:
pkgs.testers.runNixOSTest {
  name = "torrent-dns";
  nodes.machine =
    { lib, pkgs, ... }:
    let
      users = [
        "qbittorrent"
        "prowlarr"
        "radarr"
        "sonarr"
        "flaresolverr"
      ];
    in
    {
      imports = [ (import ../modules/hosts/bachus/torrent-dns.nix).flake.modules.nixos.bachus ];
      services.resolved = {
        enable = true;
        settings.Resolve = {
          DNS = "127.0.0.1";
          Domains = "~.";
          FallbackDNS = "";
        };
      };
      networking.useDHCP = false;
      networking.firewall.enable = false;
      environment.systemPackages = [ pkgs.getent ];
      users.groups = lib.genAttrs users (_: { });
      users.users = lib.genAttrs users (user: {
        isSystemUser = true;
        group = user;
      });
      systemd.services = {
        host-dns = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig.ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --no-resolv --no-hosts --bind-interfaces --listen-address=127.0.0.1 --address=/probe.test/192.0.2.10";
        };
        proton-dns = {
          wantedBy = [ "multi-user.target" ];
          preStart = "${pkgs.iproute2}/bin/ip address replace 10.2.0.1/32 dev lo";
          serviceConfig.ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --no-resolv --no-hosts --bind-interfaces --listen-address=10.2.0.1 --address=/probe.test/192.0.2.20";
        };
      }
      // lib.genAttrs users (user: {
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = user;
          StateDirectory = "${user}-dns";
        };
        script = ''
          ${pkgs.getent}/bin/getent ahostsv4 probe.test > /var/lib/${user}-dns/result
        '';
      });
    };
  testScript = ''
    start_all()
    machine.wait_for_unit("systemd-resolved.service")
    machine.wait_for_unit("nscd.service")
    machine.wait_for_unit("host-dns.service")
    machine.wait_for_unit("proton-dns.service")
    machine.succeed("getent ahostsv4 probe.test | grep 192.0.2.10")
    users = ["qbittorrent", "prowlarr", "radarr", "sonarr", "flaresolverr"]
    for user in users:
        machine.succeed(f"systemctl start {user}.service")
        machine.succeed(f"grep 192.0.2.20 /var/lib/{user}-dns/result")
        machine.fail(f"grep 192.0.2.10 /var/lib/{user}-dns/result")
    machine.succeed("systemctl stop proton-dns.service")
    for user in users:
        machine.fail(f"systemctl restart {user}.service")
    machine.succeed("getent ahostsv4 probe.test | grep 192.0.2.10")
    machine.succeed("systemctl start proton-dns.service")
    for user in users:
        machine.succeed(f"systemctl restart {user}.service")
        machine.succeed(f"grep 192.0.2.20 /var/lib/{user}-dns/result")
  '';
}
