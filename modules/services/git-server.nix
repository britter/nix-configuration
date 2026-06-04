_: {
  flake.modules.nixos.git-server =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      users.users.git = {
        isSystemUser = true;
        group = "git";
        description = "git user";
        home = "/srv/git";
        shell = "${pkgs.git}/bin/git-shell";
        openssh.authorizedKeys.keys = lib.attrValues config.systemConstants.adminKeys;
        useDefaultShell = true;
      };
      users.groups.git = { };
    };
}
