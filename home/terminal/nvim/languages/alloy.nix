{ pkgs, ... }:
let
  treesitter-alloy-grammar = pkgs.tree-sitter.buildGrammar {
    language = "alloy";
    version = "0.0.1+rev=3e18eb4";
    src =
      (pkgs.fetchFromGitHub {
        owner = "mattsre";
        repo = "tree-sitter-alloy";
        rev = "3e18eb4e97f06c57a3925f3d20bef6329a6eaef3";
        sha256 = "sha256-1ZQ9KkPBhK4pmkvZ7y1kEDeTs0y/fE3+2ea0cKCtQG8=";
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
            do
              local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
              parser_config.alloy = {
              install_info = {
              url = "${treesitter-alloy-grammar}",
                  files = {"src/parser.c"},
                },
              }
            end
          '';
      };
      none-ls = {
        luaConfig.post =
          # lua
          ''
            do
              local null_ls = require("null-ls")
              local alloy_fmt = {
                method = null_ls.methods.FORMATTING,
                filetypes = { "alloy" },
                name = "alloy-fmt",
                generator = require("null-ls.helpers").formatter_factory({
                  command = "${pkgs.grafana-alloy}/bin/alloy",
                  args = { "fmt" },
                  to_stdin = true,
                }),
              }
              null_ls.register(alloy_fmt)
            end
          '';
      };
    };

    extraPlugins = [ treesitter-alloy-grammar ];
  };
}
