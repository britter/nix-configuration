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
        directions = {
          hostname = osConfig.my.homelab.directions.ip;
          identityFile = privateKey;
          user = "root";
        };
        "srv-prod-1" = {
          hostname = osConfig.my.homelab.srv-prod-1.ip;
          identityFile = privateKey;
          user = "root";
        };
        "srv-prod-2" = {
          hostname = osConfig.my.homelab.srv-prod-2.ip;
          identityFile = privateKey;
          user = "root";
        };
        "srv-test-1" = {
          hostname = osConfig.my.homelab.srv-test-1.ip;
          identityFile = privateKey;
          user = "root";
        };
        "srv-test-2" = {
          hostname = osConfig.my.homelab.srv-test-2.ip;
          identityFile = privateKey;
          user = "root";
        };
        "srv-eval-1" = {
          hostname = osConfig.my.homelab.srv-eval-1.ip;
          identityFile = privateKey;
          user = "root";
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
