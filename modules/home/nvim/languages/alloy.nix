_: {
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    let
      treesitter-alloy-grammar = pkgs.tree-sitter.buildGrammar {
        language = "alloy";
        version = "0.0.1+rev=3e18eb4";
        src =
          (pkgs.fetchFromGitHub {
            owner = "mattsre";
            repo = "tree-sitter-alloy";
            rev = "58d462b1cdb077682b130caa324f3822aeb00b8e";
            sha256 = "sha256-yDYGtM/vlZqeOy2O+scGHc6Dae0H/cXyC6Gu0inwJNA=";
          }).overrideAttrs
            (_drv: {
              fixupPhase = ''
                mkdir -p $out/queries/alloy
                mv $out/queries/*.scm $out/queries/alloy/
              '';
            });
        meta.homepage = "https://github.com/mattsre/tree-sitter-alloy";
      };
    in
    {
      programs.nixvim = {
        filetype.extension = {
          alloy = "alloy";
        };
        plugins = {
          treesitter = {
            grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars ++ [
              treesitter-alloy-grammar
            ];
            luaConfig.post =
              # lua
              ''
                vim.api.nvim_create_autocmd('User', { pattern = 'TSUpdate',
                callback = function()
                  require("nvim-treesitter.parsers").alloy = {
                    install_info = {
                    url = "${treesitter-alloy-grammar}",
                        files = {"src/parser.c"},
                      },
                    }
                end})
              '';

          };
          none-ls = {
            luaConfig.post =
              # lua
              ''
                do
                  local null_ls = require("null-ls")
                  -- alloy fmt + validate now come from none-ls-extras.nvim
                  -- (nvimtools/none-ls-extras.nvim#45). `.with` pins the binary
                  -- so it doesn't have to be on nvim's PATH.
                  null_ls.register(require("none-ls.formatting.alloy").with({
                    command = "${pkgs.grafana-alloy}/bin/alloy",
                  }))
                  null_ls.register(require("none-ls.diagnostics.alloy").with({
                    command = "${pkgs.grafana-alloy}/bin/alloy",
                  }))
                end
              '';
          };
        };

        extraPlugins = [
          treesitter-alloy-grammar
        ];
      };
    };
}
