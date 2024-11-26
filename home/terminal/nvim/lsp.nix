_: {
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      gopls.enable = true;
      nixd.enable = true;
      tsserver.enable = true;
    };
    keymaps = {
      lspBuf = {
        K = "hover";
        gd = "definition";
        "<leader>ca" = "code_action";
      };
      diagnostic = {
        "[d" = "goto_prev";
        "]d" = "goto_next";
        "<C-w>d" = "open_float";
      };
    };
  };
}
