_: {
  flake.modules.homeManager.ssh =
    { config, ... }:
    {
      programs.ssh = {
        enable = true;
        # Disables default settings which used to be written by default but can cause problems
        # in some situations. This behavior will be removed at some point, which is when
        # this option setting can be removed without replacement.
        #
        # See https://github.com/nix-community/home-manager/pull/7655
        enableDefaultConfig = false;
        settings = {
          "github.com" = {
            IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
            IdentitiesOnly = true;
          };
        };
      };
    };
}
