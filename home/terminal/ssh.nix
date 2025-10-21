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
      # Disables matchBlocks.* which used to be written by default but can cause problems
      # in some situations. This behavior will be removed as some point, which is when
      # this option setting can be removed without replacement.
      #
      # See https://github.com/nix-community/home-manager/pull/7655
      enableDefaultConfig = false;
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
