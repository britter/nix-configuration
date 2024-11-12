{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.ssh-access;
in {
  options.my.modules.ssh-access = {
    enable = lib.mkEnableOption "ssh-access";
  };
  config = lib.mkIf cfg.enable {
    users.users.root.openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };
}
