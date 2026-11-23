{ inputs, ... }:
{
  flake.modules.nixos.bachus = {
    services.caddy = {
      enable = true;
      email = "sylvester@sylvesterroos.com";
    };

    services.caddy.virtualHosts."sylvesterroos.com" = {
      extraConfig = ''
        root * ${inputs.sylvesterroos-com.packages.x86_64-linux.default}
        file_server
      '';
    };

    services.caddy.virtualHosts."www.sylvesterroos.com".extraConfig = ''
      redir https://sylvesterroos.com{uri} permanent
    '';

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
