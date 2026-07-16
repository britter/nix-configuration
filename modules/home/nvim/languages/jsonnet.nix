_: {
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    {
      programs.nixvim.plugins = {
        lsp.servers.jsonnet_ls.enable = true;
        none-ls.luaConfig.post =
          # lua
          ''
            do
              local null_ls = require("null-ls")
              local helpers = require("null-ls.helpers")

              null_ls.register({
              method = null_ls.methods.FORMATTING,
              filetypes = { "jsonnet" },
              name = "jsonnetfmt",
              generator = helpers.formatter_factory({
              command = "${pkgs.go-jsonnet}/bin/jsonnetfmt",
                  args = { "-" },
                  to_stdin = true,
                }),
              })
            end
          '';
      };
    };
}
