{
  pkgs,
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
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsQc3GN4b8scuDR7PghdB+Eu4zUgSwgrgqplpNDR3Lq"
      ];
      useDefaultShell = true;
    };
    users.groups.git = { };
  };
}
