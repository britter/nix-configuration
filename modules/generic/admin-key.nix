_: {
  flake.modules.generic.admin-key =
    { lib, ... }:
    {
      options.admin-key = lib.mkOption {
        type = lib.types.str;
        description = ''
          SSH public key of the controlling machine. Used to authorize
          administrative logins on every host in the fleet.
        '';
      };
      config.admin-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsQc3GN4b8scuDR7PghdB+Eu4zUgSwgrgqplpNDR3Lq";
    };
}
