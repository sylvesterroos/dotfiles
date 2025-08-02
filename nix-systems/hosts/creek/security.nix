{ ... }:

{
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
  };

  environment.memoryAllocator.provider = "graphene-hardened-light";
}
