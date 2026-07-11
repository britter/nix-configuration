_: {
  flake.modules.homeManager.direnv = {

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.whitelist.prefix = [
        "~/github/britter"
        "~/github/gradlex-org"
        "~/codeberg.org/britter"
      ];
    };
    programs.git.ignores = [ ".direnv" ];

  };
}
