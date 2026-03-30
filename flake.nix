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
          rev = "3d5dcbdab31fe0c132f42dc3d725fe8ab2d01403";
          version = "0.41.25-britter.5";
          hash = "sha256-+nwEArYRA/36TFKSpW2Qm01ipsXqjYA3mtVuQWqCLXw=";
          vendorHash = "sha256-OVdhM8Zqnm1J8KducnkNkroBoSLER3fHfZBjyp7kBu8=";
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
