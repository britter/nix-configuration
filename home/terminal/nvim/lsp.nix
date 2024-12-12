_: {
  programs.nixvim.plugins.lsp = {
    enable = true;
    inlayHints = true;
    servers = {
      gopls.enable = true;
      nixd.enable = true;
      ts_ls.enable = true;
    };
    onAttach =
      # lua
      ''
        if client.supports_method('textDocument/formatting') then
          -- Format the current buffer on save
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = buffer;
            callback = function()
              vim.lsp.buf.format({ bufnr = buffer, id = client.id })
            end,
          })
        end
      '';
    keymaps = {
      lspBuf = {
        K = "hover";
        gd = "definition";
        "<leader>ca" = "code_action";
        "<leader>rr" = "rename";
      };
      diagnostic = {
        "[d" = "goto_prev";
        "]d" = "goto_next";
        "<C-w>d" = "open_float";
      };
    };
  };
}
