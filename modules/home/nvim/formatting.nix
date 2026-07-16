_: {
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    {
      programs.nixvim.plugins = {
        none-ls = {
          enable = true;
          sources = {
            formatting = {
              gofmt.enable = true;
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt;
              };
              prettier = {
                enable = true;
                # should be removed once https://github.com/nix-community/nixvim/pull/4234 has been merged
                package = pkgs.prettier;
                disableTsServerFormatter = true;
                settings = {
                  disabled_filetypes = [
                    "yaml"
                    "markdown"
                    "markdown.mdx"
                  ];
                };
              };
            };
            diagnostics.actionlint.enable = true;
          };
        };
        lsp = {
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
        };
      };
    };
}
