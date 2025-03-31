{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.git-server;
in
{
  options.my.modules.git-server = {
    enable = lib.mkEnableOption "git-server";
  };

  config = lib.mkIf cfg.enable {
    users.users.git = {
      isSystemUser = true;
      group = "git";
      description = "git user";
      home = "/srv/git";
      openssh.authorizedKeys.keyFiles = [ ../ssh-access/id_ed25519.pub ];
    };
    users.groups.git = { };
  };
}
