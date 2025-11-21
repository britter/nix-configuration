{ pkgs, ... }:
{
  programs.nixvim = {
    filetype.extension = {
      tofu = "tofu";
    };
    plugins = {
      lsp.servers.terraformls = {
        enable = true;
        package = pkgs.opentofu-ls;
        filetypes = [
          "tf"
          "terraform"
          "terraform-vars"
          "tfvars"
          "tofu"
        ];
      };
      treesitter = {
        enable = true;
        languageRegister = {
          hcl = [
            "tf"
            "terraform"
            "tofu"
          ];
        };
      };
      none-ls.sources = {
        diagnostics.opentofu_validate = {
          enable = true;
          settings = {
            extra_filetypes = [
              "tofu"
            ];
          };
        };
        formatting.opentofu_fmt = {
          enable = true;
          settings = {
            extra_filetypes = [
              "tofu"
            ];
          };
        };
      };
    };
  };
}
