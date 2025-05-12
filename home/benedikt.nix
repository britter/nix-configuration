{
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./desktop/intellij
    ./java
    ./terminal
  ];

  home.username = "benedikt";
  home.homeDirectory = "/home/benedikt";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  my.home = {
    desktop.intellij.enable = true;
    java = {
      enable = true;
      version = 21;
    };
    terminal = {
      enable = true;
      git.addIncludes = false;
      ssh.enable = false;
    };
  };
  programs.nixvim.plugins.none-ls.sources.formatting.google_java_format.enable = true;
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
    extraConfig = {
      gpg.x509.program = "${pkgs.gitsign}/bin/gitsign";
      gpg.format = "x509";
      gitsign.connectorID = "https://accounts.google.com";
    };
    includes = [
      {
        condition = "gitdir:~/github/britter/";
        contents = {
          gpg.format = "openpgp";
          user.email = "beneritter@gmail.com";
          user.signingKey = "14907572088F4FA7";
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
  home.packages = with pkgs; [
    argo
    crane
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    grype
    kubectl
    kubectx
    maven
    melange
    syft
    terraform
    yubikey-manager
  ];
}
