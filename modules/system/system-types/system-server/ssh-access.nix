_: {
  flake.modules.nixos.system-server =
    { config, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [ config.admin-key ];

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
      };
    };
}
