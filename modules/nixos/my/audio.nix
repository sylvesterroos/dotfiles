{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.audio;
in
{
  options.my.audio = {
    enable = mkEnableOption "audio" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    programs.noisetorch.enable = true;
  };
}
