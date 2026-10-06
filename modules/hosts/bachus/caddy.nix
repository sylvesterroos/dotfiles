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

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
