_: {
  flake.modules.homeManager.nvim =
    { config, pkgs, ... }:
    {
      programs.nixvim = {
        plugins.lsp = {
          enable = true;
          inlayHints = true;
          servers = {
            astro.enable = true;
            gopls.enable = true;
            kotlin_lsp = {
              enable = true;
              package = pkgs.kotlin-lsp;
            };
            nixd.enable = true;
            rust_analyzer = {
              enable = config.programs.cargo.enable;
              installCargo = true;
              installRustc = true;
              installRustfmt = true;
            };
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
