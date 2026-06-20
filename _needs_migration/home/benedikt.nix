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
    ./terminal
  ];

  programs.home-manager.enable = true;

  my.home = {
    terminal = {
      enable = true;
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
