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
              local helpers = require("null-ls.helpers")

              local alloy_fmt = {
                method = null_ls.methods.FORMATTING,
                filetypes = { "alloy" },
                name = "alloy-fmt",
                generator = helpers.formatter_factory({
                  command = "${pkgs.grafana-alloy}/bin/alloy",
                  args = { "fmt" },
                  to_stdin = true,
                }),
              }
              null_ls.register(alloy_fmt)

              local pattern = [[^([%w]+):%s*(.-):(%d+):(%d+):%s*(.*)$]]
              local alloy_validate = {
                method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
                filetypes = { "alloy" },
                name = "alloy-validate",
                generator = helpers.generator_factory({
                  command = "${pkgs.grafana-alloy}/bin/alloy",
                  args = { "validate", "$FILENAME" },
                  format = "line",
                  to_stdin = false,
                  from_stderr = true,
                  on_output = function(line, params)
                    -- Only match the diagnostic header line. Ignore all others.
                    local severity, filename, lnum, col, msg =
                      line:match(pattern)

                    if not severity then
                        return nil
                    end

                    local sevmap = {
                      Error   = helpers.diagnostics.severities.error,
                      Warning = helpers.diagnostics.severities.warning,
                    }

                    return {
                      row      = tonumber(lnum),
                      col      = tonumber(col),
                      end_col  = tonumber(col) + 1, -- mark single char
                      source   = "alloy",
                      message  = msg,
                      severity = sevmap[severity] or helpers.diagnostics.severities.error,
                      filename = filename,
                    }
                  end,
                }),
              }
              null_ls.register(alloy_validate) end
          '';
      };
    };

    extraPlugins = [ treesitter-alloy-grammar ];
  };
}
