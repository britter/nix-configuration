{
  pkgs,
  config,
  ...
}:

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
  programs.git = {
    includes = [
      {
        condition = "gitdir:~/github/chainguard-dev/";
        contents = {
          gpg.x509.program = "${pkgs.gitsign}/bin/gitsign";
          gpg.format = "x509";
          gitsign.connectorID = "https://accounts.google.com";
        };
      }
    ];
  };
  home.sessionVariables = {
    GITSIGN_CREDENTIAL_CACHE = "${config.home.homeDirectory}/.cache/sigstore/gitsign/cache.sock";
  };
  systemd.user = {
    enable = true;
    services = {
      gitsign-credential-cache = {
        Unit = {
          Description = "GitSign credential cache";
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.gitsign}/bin/gitsign-credential-cache";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
    sockets = {
      gitsign-credential-cache = {
        Unit = {
          Description = "GitSign credential cache socket";
        };
        Socket = {
          ListenStream = "%C/sigstore/gitsign/cache.sock";
          DirectoryMode = "0700";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
