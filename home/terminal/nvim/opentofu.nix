_: {
  programs.nixvim = {
    filetype.extension = {
      tofu = "tofu";
    };
    plugins = {
      lsp.servers.terraformls = {
        enable = true;
        filetypes = ["tf" "terraform" "terraform-vars" "tfvars" "tofu"];
      };
      treesitter = {
        enable = true;
        languageRegister = {
          hcl = ["tf" "terraform" "tofu"];
        };
      };
      none-ls.sources.formatting.opentofu_fmt = {
        enable = true;
        settings = {
          extra_filetypes = [
            "tofu"
          ];
        };
      };
    };
  };
}
