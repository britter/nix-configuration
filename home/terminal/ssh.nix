{
  config,
  lib,
  osConfig,
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
          mkHost = host: {
            "${host}.ritter.family" = {
              identityFile = privateKey;
              user = "root";
              # fix for ghostty until servers update to ncurses 6.5+, see https://ghostty.org/docs/help/terminfo
              setEnv = {
                TERM = "xterm-256color";
              };
            };
          };
          myHosts = lib.map mkHost [
            "directions"
            "srv-prod-1"
            "srv-prod-2"
            "srv-test-1"
            "srv-test-2"
            "srv-eval-1"
            "srv-backup-1"
          ];
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
                hostname = osConfig.my.homelab.srv-prod-2.ip;
                identityFile = privateKey;
                user = "git";
              };
            }
          ]
        );
    };
  };
}
