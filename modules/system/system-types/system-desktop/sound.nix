_: {
  flake.modules.nixos.system-desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.pavucontrol ];
      services.pulseaudio.enable = false;
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
