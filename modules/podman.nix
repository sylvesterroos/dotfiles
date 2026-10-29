{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      users.users.sylvester = {
        linger = true;

        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];

        extraGroups = [
          "podman"
        ];
      };

      virtualisation = {
        containers.enable = true;
        oci-containers.backend = "podman";
        podman = {
          enable = true;

          # Create a `docker` alias for podman, to use it as a drop-in replacement
          dockerCompat = true;

          # let docker tools find the podman socket
          # user needs to be in the podman group
          dockerSocket.enable = true;

          # Required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      environment.sessionVariables.PODMAN_COMPOSE_WARNING_LOGS = "false";
      systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];
      environment.systemPackages = with pkgs; [ podman-compose ];
    };

  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        podman-desktop
        podman-tui
        pods
      ];
    };
}
