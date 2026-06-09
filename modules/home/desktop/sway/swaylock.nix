{
  flake.modules.nixos.swaylock = {
    # Allow swaylock to unlock the computer for us
    security.pam.services.swaylock = {
      text = "auth include login";
    };
  };

  flake.modules.homeManager.swaylock =
    { pkgs, ... }:
    {
      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          screenshots = true;
          daemonize = true;
          ignore-empty-password = true;
          clock = true;
          indicator = true;
          effect-blur = "10x5";
          effect-vignette = "0.5:1";
        };
      };
    };
}
