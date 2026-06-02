_: {
  flake.modules.nixos.system-server =
    { config, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [ config.systemConstants.adminKey ];

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
      };
    };
}
