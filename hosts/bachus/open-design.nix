{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  services.open-design.webFrontend.package =
    inputs.open-design.packages.${pkgs.stdenv.hostPlatform.system}.web.overrideAttrs
      (old: {
        pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
          outputHash = "sha256-TI7gjjF47YIkLblWjG9flG3E1mg310AI5S4uZ+9B2kI=";
        });
      });

  services.open-design = {
    enable = true;
    autoStart = true;
    webFrontend = {
      enable = true;
      allowedOrigins = [ "https://open-design.sylvesterroos.com" ];
    };
  };

  # Avoid NixOS' generated service PATH so open-design's own PATH is used.
  systemd.services.open-design.path = lib.mkForce [ ];

  services.caddy.virtualHosts."open-design.sylvesterroos.com".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.open-design.webFrontend.port}
  '';
}
