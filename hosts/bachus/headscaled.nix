# Publishes selected bachus services on the headscale tailnet. bachus is the
# only node there offering anything: headscaled forwards port 443 of its
# headscale address to a Caddy listener on loopback, and Caddy routes each
# published hostname to its service. That listener hosts nothing else, so the
# public sites and every other port stay out of reach of the headscale tailnet.
#
# The ACL policy grants every headscale user port 443 on nodes carrying the
# server tag, and pocket-id decides who becomes a headscale user. Only an admin
# can apply the tag; headscaled-publish applies it to bachus's headscaled node.
#
# Each hostname resolves to bachus's headscale address through a MagicDNS
# record. headscale assigns the address on first login, so headscaled-publish
# writes the records once headscaled is up. Until then they point at loopback.
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
  my.headscaled.enable = true;

  # Only an admin applies the server tag, so no user can claim it.
  services.headscale.settings.policy = {
    mode = "file";
    path = json "policy.hujson" {
      tagOwners.${serverTag} = [ ];
      acls = [
        {
          action = "accept";
          src = [ "autogroup:member" ];
          dst = [ "${serverTag}:${toString publishedPort}" ];
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
}
