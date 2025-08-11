_: {
  programs.nixvim = {
    plugins.telescope.enable = true;
    plugins.lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        astro.enable = true;
        gopls.enable = true;
        nixd.enable = true;
        terraformls.enable = true;
        ts_ls.enable = true;
      };
      luaConfig.pre = ''
        local augroup = vim.api.nvim_create_augroup('Autoformat', {})

        local function format(buf)
          local null_ls_sources = require('null-ls.sources')
          local ft = vim.bo[buf].filetype

          local has_null_ls = #null_ls_sources.get_available(ft, 'NULL_LS_FORMATTING') > 0

          vim.lsp.buf.format({
            bufnr = buf,
            filter = function(client)
              if has_null_ls then
                return client.name == 'null-ls'
              else
                return true
              end
            end,
          })
        end
      '';
      onAttach =
        # lua
        ''
          if client.supports_method('textDocument/formatting') then
             vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            -- Format the current buffer on save
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = augroup;
              buffer = bufnr;
              callback = function()
                if vim.b.format_on_write ~= false then
                  format(bufnr)
                end
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
      };
    };
    keymaps = [
      {
        action = "<cmd>Telescope lsp_document_symbols<CR>";
        key = "<leader>o";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>";
        key = "<leader>O";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Telescope lsp_incoming_calls<CR>";
        key = "<leader>fu";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Telescope lsp_references<CR>";
        key = "<leader>fU";
        mode = [ "n" ];
      }
      {
        action = "<cmd>Telescope lsp_implementations<CR>";
        key = "<leader>fi";
        mode = [ "n" ];
      }
    ];
  };
}
