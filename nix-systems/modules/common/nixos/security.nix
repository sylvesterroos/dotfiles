{...}: {
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
  };

  # Loupe doesn't work with 'graphene-hardened*'
  # environment.memoryAllocator.provider = "graphene-hardened-light";
}
