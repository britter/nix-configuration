{ config, ... }:
let
  inherit (config.flake.modules.homeManager) nodejs;
in
{
  flake.modules.homeManager.chainguard-development-tools = { config, pkgs, ... }: {
    imports = [ nodejs ];

    home.sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/go/bin"
    ];

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
      syft
      terraform
      witness
      yubikey-manager
    ];
  };

}
