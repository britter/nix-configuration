{ config, ... }:

{
  imports = [
    ./java
    ./terminal
  ];

  home.username = "benedikt";
  home.homeDirectory = "/home/benedikt";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  my.home = {
    java = {
      enable = true;
      version = 21;
      additionalVersions = [
        8
        11
        17
      ];
    };
    terminal = {
      enable = true;
      git.addIncludes = false;
      ssh.enable = false;
      gpg.enable = false;
    };
  };
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };
}
