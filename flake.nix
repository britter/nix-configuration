{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      utils,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        unifly = pkgs.callPackage ./packages/unifly.nix { };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            jq
            minio-client
            opentofu
            sops
            unifly
          ];
        };
      }
    );
}
