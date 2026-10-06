{
  flake.modules.nixos.delta = {
    services.lact.enable = true;
    hardware.amdgpu.overdrive.enable = true;
  };
}
