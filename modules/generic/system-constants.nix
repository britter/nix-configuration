_: {
  flake.modules.generic.systemConstants =
    { lib, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
        description = ''
          System-wide constants — values that are the same on every
          host in the fleet and don't fit any existing aspect.
        '';
      };
      config.systemConstants = {
        adminKeys = {
          framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsQc3GN4b8scuDR7PghdB+Eu4zUgSwgrgqplpNDR3Lq";
          starlite = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2+ifShP1n5ZV8Q/VKXvpdKAJycgQ0kgkiz7YOPmKec";
        };
        configRepo = "https://github.com/britter/nix-configuration.git";
      };
    };
}
