_: {
  programs.nixvim.plugins.lsp = {
    enable = true;
    inlayHints = true;
    servers = {
      gopls.enable = true;
      nixd.enable = true;
      ts_ls.enable = true;
    };
    keymaps = {
      lspBuf = {
        K = "hover";
        gd = "definition";
        "<leader>ca" = "code_action";
        "<leader>rr" = "rename";
        "<leader>gq" = "format";
      };
      diagnostic = {
        "[d" = "goto_prev";
        "]d" = "goto_next";
        "<C-w>d" = "open_float";
      };
    };
  };
}
