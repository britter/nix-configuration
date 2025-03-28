{
  config,
  lib,
  osConfig,
  ...
}: let
  cfg = config.my.home.terminal.ssh;
in {
  options.my.home.terminal.ssh = {
    enable = lib.mkEnableOption "ssh";
  };
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      matchBlocks = let
        sshDirectory = "${config.home.homeDirectory}/.ssh";
        privateKey = "${sshDirectory}/id_ed25519";
      in {
        "github.com" = {
          hostname = "github.com";
          identityFile = privateKey;
          identitiesOnly = true;
        };
        "directions.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          # fix for ghostty until servers update to ncurses 6.5+, see https://ghostty.org/docs/help/terminfo
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "srv-prod-1.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "srv-prod-2.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "srv-test-1.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "srv-test-2.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "srv-eval-1.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "srv-backup-1.ritter.family" = {
          identityFile = privateKey;
          user = "root";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
        "git.ritter.family" = {
          hostname = osConfig.my.homelab.srv-prod-2.ip;
          identityFile = privateKey;
          user = "git";
        };
      };
    };
  };
}
