{
  config,
  lib,
  ...
}: {
  virtualisation.oci-containers = lib.mkIf config.my.podman.enable {
    containers.immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release-rocm";
      ports = ["3003:3003"];
      volumes = [
        "immich-model-cache:/cache"
      ];
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
        "--device=/dev/kfd:/dev/kfd"
        "--group-add=video"
      ];
    };
  };
}
