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
        adminEmail = "beneritter@gmail.com";
        baseDomain = "ritter.family";
        adminKeys = {
          framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsQc3GN4b8scuDR7PghdB+Eu4zUgSwgrgqplpNDR3Lq";
          starlite = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2+ifShP1n5ZV8Q/VKXvpdKAJycgQ0kgkiz7YOPmKec";
          yubikey-primary = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMia4/q9Uo/dnfa4FpJGBQhY/4JOc0ESg1tQbI7IprVeAAAABHNzaDo= login-primary";
        };
        configRepo = "https://github.com/britter/nix-configuration.git";
      };
    };
}
