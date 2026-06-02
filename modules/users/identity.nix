_: {
  flake.modules.homeManager.user-identity =
    { lib, ... }:
    {
      options.user = {
        fullName = lib.mkOption {
          type = lib.types.str;
          description = "Full name for git/email/etc.";
        };
        email = lib.mkOption {
          type = lib.types.str;
          description = "Email for git/email/etc.";
        };
        signingKey = lib.mkOption {
          type = lib.types.str;
          description = "GPG signing key ID.";
        };
      };
    };
}
