{ inputs, ... }: {
  flake.modules.homeManager.direnv = {

    imports = [ inputs.direnv-instant.homeModules.direnv-instant ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.whitelist.prefix = [
        "~/britter.dev"
        "~/github/britter"
        "~/github/gradlex-org"
        "~/codeberg.org/britter"
      ];
    };
    programs.direnv-instant.enable = true;
    programs.git.ignores = [ ".direnv" ];

  };
}
