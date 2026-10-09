# Publishes selected Bachus services through a loopback Caddy listener and
# MagicDNS records. The policy grants members HTTPS access to those services,
# and grants Sylvester's devices and Bachus SSH access to the tagged Deck.
# Bachus can also reach the Deck's HTTP service on port 8787 through its proxy.
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domain = config.services.headscale.settings.dns.base_domain;
      listenAddress = "127.0.0.1";
      listenPort = 8443;
      # Port of bachus's headscale address that serves the sites.
      publishedPort = 443;

      # Hostname prefix → local upstream, for the services flagged `headscale`.
      services = lib.listToAttrs (
        map (s: lib.nameValuePair s.name s.target) (
          lib.filter (s: s.headscale) config.my.tailnet-services.services
        )
      );

      recordsFile = config.services.headscale.settings.dns.extra_records_path;
      serverTag = "tag:server";

      # The record type stays empty: Tailscale infers A or AAAA from the value,
      # and its userspace proxy resolves only records without a type.
      records =
        address:
        lib.mapAttrsToList (name: _: {
          name = "${name}.${domain}";
          value = address;
        }) services;

      json = name: value: pkgs.writeText name (builtins.toJSON value);
    in
    {
      my.headscaled = {
        enable = true;
        httpProxy = {
          listen = "localhost:1055";
          inherit domain;
        };
      };

      # An admin assigns the server and Deck identities.
      services.headscale.settings.policy = {
        mode = "file";
        path = json "policy.hujson" {
          tagOwners = {
            ${serverTag} = [ ];
            "tag:deck" = [ ];
          };
          acls = [
            {
              action = "accept";
              src = [
                "autogroup:member"
                "tag:deck"
              ];
              dst = [ "${serverTag}:${toString publishedPort}" ];
            }
            {
              action = "accept";
              proto = "tcp";
              src = [
                "sylvester@"
                serverTag
              ];
              dst = [ "tag:deck:22" ];
            }
            {
              action = "accept";
              proto = "tcp";
              src = [ serverTag ];
              dst = [ "tag:deck:8787" ];
            }
            # Skyrim Together
            {
              action = "accept";
              src = [ "fred@" ];
              dst = [
                "sylvester@:10578"
                "tag:deck:10578"
              ];
            }
            # Project Zomboid
            {
              action = "accept";
              proto = "udp";
              src = [ "autogroup:member" ];
              dst =
                let
                  ports = config.services.pznix.servers.zomboid.ports;
                in
                map (port: "${serverTag}:${toString port}") ([ ports.game ] ++ map (p: p.port) ports.extra);
            }
          ];
          ssh = [
            {
              action = "accept";
              src = [
                "sylvester@"
                serverTag
              ];
              dst = [ "tag:deck" ];
              users = [ "deck" ];
            }
          ];
        };
      };

      # headscale refuses to start without the records file, so a loopback
      # placeholder is installed when it is missing. An existing file stays:
      # headscale tracks it by inode, and replacing it ends the watch.
      systemd.services.headscaled-seed = {
        description = "Seed headscale's MagicDNS records";
        wantedBy = [ "multi-user.target" ];
        before = [ "headscale.service" ];
        requiredBy = [ "headscale.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # headscale's own state directory and user, so the directory exists
          # before headscale starts and keeps headscale as its owner.
          inherit (config.systemd.services.headscale.serviceConfig)
            User
            Group
            StateDirectory
            StateDirectoryMode
            ;
          ExecStart = "${lib.getExe' pkgs.coreutils "cp"} --update=none ${json "extra-records.json" (records "127.0.0.1")} ${recordsFile}";
        };
      };

      systemd.services.headscaled-publish = {
        description = "Publish services on the headscale tailnet";
        wantedBy = [ "multi-user.target" ];
        after = [
          "headscale.service"
          "headscaled.service"
          "headscaled-seed.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writers.writeNu "headscaled-publish" { } ./headscaled-publish.nu;
          Environment = lib.mapAttrsToList (name: value: "${name}=${value}") {
            TAILSCALE = lib.getExe config.my.headscaled.package;
            SOCKET = config.my.headscaled.socket;
            HEADSCALE = lib.getExe config.services.headscale.package;
            TAG = serverTag;
            SERVE_PORT = toString publishedPort;
            SERVE_TARGET = "tcp://${listenAddress}:${toString listenPort}";
            RECORDS_FILE = recordsFile;
            # A file: systemd's Environment= parsing strips the quotes inside a
            # JSON value.
            RECORDS_TEMPLATE = json "records-template.json" (records "@ADDRESS@");
          };
          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      # Certificates come through DNS-01 (Porkbun): the hostnames resolve to a
      # tailnet address, which HTTP-01 cannot reach.
      services.caddy.virtualHosts = lib.mapAttrs' (
        name: upstream:
        lib.nameValuePair "${name}.${domain}:${toString listenPort}" {
          listenAddresses = [ listenAddress ];
          extraConfig = ''
            tls {
              dns porkbun {
                api_key {env.PORKBUN_API_TOKEN}
                api_secret_key {env.PORKBUN_SECRET_API_KEY}
              }
            }

            reverse_proxy ${upstream}
          '';
        }
      ) services;
    };
}
