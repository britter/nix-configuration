_: {
  programs.nixvim = {
    filetype.extension = {
      tofu = "tofu";
    };
    plugins = {
      lsp.servers.terraformls = {
        enable = true;
        filetypes = ["terraform" "tfvars" "tofu"];
      };
      treesitter = {
        enable = true;
        languageRegister = {
          hcl = ["terraform" "tofu"];
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
