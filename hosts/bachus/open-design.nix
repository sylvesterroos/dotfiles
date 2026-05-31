{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  openDesignPackages = inputs.open-design.packages.${system};

  # Upstream's fixed-output pnpm dependency derivation has a stale hash.
  # Override it locally until the open-design flake updates its package hash.
  daemonPnpmDepsHash = "sha256-tqxFDNPQjoKUWp4sLtPVCUu7ltIL/ufeyr6UKOWYw6A=";
  webPnpmDepsHash = "sha256-74loUCL+WcaZO4AAMnSpNeBhDz1Y9TMgFRPbyaOfPAk=";
  fixPnpmDepsHash =
    hash: package:
    package.overrideAttrs (oldAttrs: {
      pnpmDeps = oldAttrs.pnpmDeps.overrideAttrs (_: {
        outputHash = hash;
      });
    });
in
{
  services.open-design.package = fixPnpmDepsHash daemonPnpmDepsHash openDesignPackages.daemon;
  services.open-design.webFrontend.package = fixPnpmDepsHash webPnpmDepsHash openDesignPackages.web;

  sops.templates."open-design.env" = {
    content = ''
      OD_API_KEY=${config.sops.placeholder."open-design/OD_API_KEY"}
      OD_BASIC_AUTH_USERNAME=${config.sops.placeholder."open-design/username"}
      OD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."open-design/password"}
    '';
    restartUnits = [
      "open-design.service"
      "caddy.service"
    ];
  };

  services.open-design = {
    enable = true;
    autoStart = true;
    environmentFile = config.sops.templates."open-design.env".path;
    webFrontend = {
      # Serve the web frontend from the public Caddy virtual host below instead
      # of starting Open Design's bundled localhost Caddy service.
      enable = false;
      allowedOrigins = [ "https://open-design.sylvesterroos.com" ];
    };
  };

  # Avoid NixOS' generated service PATH so open-design's own PATH is used.
  systemd.services.open-design.path = lib.mkForce [ ];

  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."open-design.env".path;

  services.caddy.virtualHosts."open-design.sylvesterroos.com".extraConfig = ''
    basic_auth {
      {$OD_BASIC_AUTH_USERNAME} {$OD_BASIC_AUTH_PASSWORD}
    }

    handle /api/* {
      reverse_proxy 127.0.0.1:${toString config.services.open-design.port} {
        flush_interval -1
        transport http {
          read_timeout 86400s
          write_timeout 86400s
        }
      }
    }

    handle /artifacts/* {
      reverse_proxy 127.0.0.1:${toString config.services.open-design.port}
    }

    handle /frames/* {
      reverse_proxy 127.0.0.1:${toString config.services.open-design.port}
    }

    handle {
      root * ${config.services.open-design.webFrontend.package}
      try_files {path} {path}/ /index.html
      file_server
      encode gzip
    }
  '';
}
