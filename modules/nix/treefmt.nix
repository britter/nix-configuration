{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        deadnix.enable = true;
        keep-sorted.enable = true;
        nixfmt.enable = true;
        statix.enable = true;
        stylua.enable = true;
        # Format the OpenTofu (HCL) files under tofu/ with `tofu fmt`.
        terraform.enable = true;
      };
      settings.formatter.stylua.options = [
        "--indent-type"
        "Spaces"
      ];
    };
  };
}
