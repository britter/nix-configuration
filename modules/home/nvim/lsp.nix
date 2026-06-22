_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim = {
      plugins.lsp = {
        enable = true;
        inlayHints = true;
        # Languages with non-trivial config (kotlin_lsp, rust_analyzer) live
        # in languages/*.nix. A language gets its own file only when it has
        # something beyond `enable = true;`.
        servers = {
          astro.enable = true;
          gopls.enable = true;
          nixd.enable = true;
          ts_ls.enable = true;
          zls.enable = true;
        };
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
  };
}
