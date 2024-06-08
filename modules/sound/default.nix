{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.sound;
in {
  options.my.modules.sound = {
    enable = lib.mkEnableOption "sound";
  };

  config = lib.mkIf cfg.enable {
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    # The PulseAudio server uses this to acquire realtime priority
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
