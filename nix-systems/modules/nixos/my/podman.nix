{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.podman;
in {
  options.my.podman = {
    enable =
      mkEnableOption "podman"
      // {
        default = false;
      };
  };

  config = mkIf cfg.enable {
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
        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };
    };
  };
}
