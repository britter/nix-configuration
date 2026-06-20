_: {
  flake.modules.homeManager.ssh-home-lab =
    { config, lib, ... }:
    {
      programs.ssh = {
        settings =
          let
            privateKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
            mkHost = _k: v: {
              "${v.dns}" = {
                IdentityFile = privateKey;
                User = "root";
                # fix for ghostty until servers update to ncurses 6.5+, see https://ghostty.org/docs/help/terminfo
                SetEnv = {
                  TERM = "xterm-256color";
                };
              };
            };
            myHosts = lib.mapAttrsToList mkHost config.home-lab.hosts;
          in
          lib.mkMerge (
            myHosts
            ++ [
              {
                "git.ritter.family" = {
                  HostName = config.home-lab.hosts.srv-prod-2.ip;
                  IdentityFile = privateKey;
                  User = "git";
                };
              }
            ]
          );
      };
    };
}
