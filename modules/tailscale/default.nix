{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.tailscale;
in
{
  options.my.modules.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."tailscale/auth-key" = { };

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/auth-key".path;
    };
  };
}
