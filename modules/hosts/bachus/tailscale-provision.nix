# The tailnet policy and the Tailscale Services that `my.tailnet-services`
# publishes, applied by OpenTofu on every switch. The state lives on this host.
#
# Bootstrap: create an OAuth client in the admin console with the `services`
# and `policy_file` write scopes, store its ID and secret as sops
# `tailscale/oauth_client_id` and `tailscale/oauth_client_secret`, then import
# this module.
{ config, ... }:
let
  inherit (config) tofuProvision;
in
{
  flake.modules.nixos.tailscale-provision =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceNames = map (service: "svc:${service.name}") config.my.tailnet-services.services;

      policy = {
        tagOwners."tag:server" = [ "autogroup:admin" ];
        acls = [
          {
            action = "accept";
            src = [ "*" ];
            dst = [ "*:*" ];
          }
        ];
        # Services bachus (tag:server) may advertise without console approval.
        autoApprovers.services = lib.genAttrs serviceNames (_: [ "tag:server" ]);
        # Services are deny-by-default destinations.
        grants = [
          {
            src = [ "autogroup:member" ];
            dst = serviceNames;
            ip = [ "*" ];
          }
        ];
        ssh = [
          {
            action = "check";
            src = [ "autogroup:member" ];
            dst = [ "autogroup:self" ];
            users = [
              "autogroup:nonroot"
              "root"
            ];
          }
        ];
        nodeAttrs = [
          {
            target = [ "autogroup:member" ];
            attr = [ "funnel" ];
          }
        ];
      };

      configuration = {
        terraform.required_providers.tailscale.source = "tailscale/tailscale";
        resource.tailscale_service = lib.listToAttrs (
          map (
            service:
            lib.nameValuePair service.name {
              name = "svc:${service.name}";
              ports = [ "tcp:443" ];
            }
          ) config.my.tailnet-services.services
        );
        resource.tailscale_acl.policy.acl = builtins.toJSON policy;
        import = [
          {
            to = "tailscale_acl.policy";
            id = "acl";
          }
        ];
      };
    in
    {
      sops.secrets = {
        "tailscale/oauth_client_id" = { };
        "tailscale/oauth_client_secret" = { };
      };

      systemd.services.tailscale-provision =
        tofuProvision {
          inherit pkgs configuration;
          name = "tailscale-provision";
          description = "Define the Tailscale Services of this host";
          plugins = p: [ p.tailscale_tailscale ];
          credentials = {
            TAILSCALE_OAUTH_CLIENT_ID = config.sops.secrets."tailscale/oauth_client_id".path;
            TAILSCALE_OAUTH_CLIENT_SECRET = config.sops.secrets."tailscale/oauth_client_secret".path;
          };
        }
        // {
          before = [ "tailnet-services-apply.service" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };
    };
}
