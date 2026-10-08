{
  mv,
  serviceFrom,
  ...
}:
{
  flake.modules.nixos.bachus =
    { ... }:
    {
      imports = [
        (serviceFrom {
          pkgs = mv.tip;
          name = "open-webui";
          module = "services/misc/open-webui.nix";
        })
      ];

      services.open-webui = {
        enable = true;
        port = 3000;
        host = "127.0.0.1";
        openFirewall = false;
        environment = {
          # Skip chunking + embedding on upload; file text goes straight to the agent as context.
          BYPASS_EMBEDDING_AND_RETRIEVAL = "True";
        };
      };

      # Tailnet-only via tailnet-services.nix (open-webui.<tailnet>.ts.net).
    };
}
