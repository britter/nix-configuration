{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        terraform-provider-unifi-britter = pkgs.terraform-providers.mkProvider {
          owner = "britter";
          repo = "terraform-provider-unifi";
          rev = "ee80fd993d92382cfbb7ea2220c16f8934be5b80";
          version = "0.41.25-britter.6";
          hash = "sha256-fcO7D/gL065+X1fc37fpiTf+Ell0AePPO9moeutMthw=";
          vendorHash = "sha256-m7CxgfuoO6SJ0Begke65BxaeBMmzbMkY4N6lEl46pZU=";
          homepage = "https://registry.terraform.io/providers/ubiquiti-community/unifi";
          provider-source-address = "registry.terraform.io/ubiquiti-community/unifi";
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            jq
            minio-client
            (opentofu.withPlugins (_: [ terraform-provider-unifi-britter ]))
            sops
          ];
        };
      }
    );
}
