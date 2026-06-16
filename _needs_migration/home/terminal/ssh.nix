{
  config,
  lib,
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
      # Disables default settings which used to be written by default but can cause problems
      # in some situations. This behavior will be removed at some point, which is when
      # this option setting can be removed without replacement.
      #
      # See https://github.com/nix-community/home-manager/pull/7655
      enableDefaultConfig = false;
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
              "github.com" = {
                IdentityFile = privateKey;
                IdentitiesOnly = true;
              };
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
