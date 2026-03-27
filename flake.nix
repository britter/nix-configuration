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
          rev = "2eb1d1ab9d1ecbb323f8ba4d346dfedfd95a6fdc";
          version = "0.41.25-britter";
          hash = "sha256-8ixnM6FRf0fYKz2FdcI0wiSly8tRofMI2zes7MdcaU8=";
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
