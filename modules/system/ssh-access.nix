_: {
  flake.modules.nixos.ssh-access =
    { config, lib, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = lib.attrValues config.systemConstants.adminKeys;

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
      };
    };
}
