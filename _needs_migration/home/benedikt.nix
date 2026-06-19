{
  pkgs,
  lib,
  config,
  ...
}:
let
  npmGlobalDir = "${config.home.homeDirectory}/.npm-global";
in
{
  imports = [
    ./java
    ./terminal
  ];

  programs.home-manager.enable = true;

  my.home = {
    java = {
      enable = true;
      version = 25;
    };
    terminal = {
      enable = true;
      git.addIncludes = false;
    };
  };

  programs.nixvim = {
    plugins = {
      none-ls.sources.formatting.google_java_format.enable = true;
    };
  };

  programs.ssh = {
    enable = true;
    # Disables default settings which used to be written by default but can cause problems
    # in some situations. This behavior will be removed at some point, which is when
    # this option setting can be removed without replacement.
    #
    # See https://github.com/nix-community/home-manager/pull/7655
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
    };
  };
  programs.git = {
    settings = {
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
      {
        condition = "gitdir:~/github/gradlex-org/";
        contents = {
          gpg.format = "openpgp";
          user.email = "benedikt@gradlex.org";
          user.signingKey = "6C9C4BE5D6A7FCCC";
        };
      }
    ];
    ignores = [
      ".claude/settings.local.json"
    ];
  };

  systemd.user.tmpfiles.rules = [
    "d ${npmGlobalDir} 0700 ${config.home.username} - -"
  ];
  home.sessionPath = [
    "${npmGlobalDir}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
  ];
  # Run npm config set during activation to store prefix in ~/.npmrc
  home.activation.setNpmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.nodejs}/bin/npm config set prefix ${npmGlobalDir}
  '';

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
    argo-workflows
    cosign
    crane
    # see https://github.com/NixOS/nixpkgs/issues/478005
    # dotenvx
    go
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    grype
    inetutils
    kubectl
    kubectx
    maven
    melange
    nodejs
    syft
    terraform
    witness
    yubikey-manager
  ];
}
