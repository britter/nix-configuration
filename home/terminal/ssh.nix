{
  config,
  lib,
  home-lab,
  ...
}:
let
  cfg = config.my.home.terminal.ssh;
in
{
  options.my.home.terminal.ssh = {
    enable = lib.mkEnableOption "ssh";
  };
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      matchBlocks =
        let
          privateKey = "${config.home.homeDirectory}/.ssh/id_ed25519";
          mkHost = _k: v: {
            "${v.dns}" = {
              identityFile = privateKey;
              user = "root";
              # fix for ghostty until servers update to ncurses 6.5+, see https://ghostty.org/docs/help/terminfo
              setEnv = {
                TERM = "xterm-256color";
              };
            };
          };
          myHosts = lib.mapAttrsToList mkHost home-lab.hosts;
        in
        lib.mkMerge (
          myHosts
          ++ [
            {
              "github.com" = {
                identityFile = privateKey;
                identitiesOnly = true;
              };
              "git.ritter.family" = {
                hostname = home-lab.hosts.srv-prod-2.ip;
                identityFile = privateKey;
                user = "git";
              };
            }
          ]
        );
    };
  };
}
