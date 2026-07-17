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
              null_ls.register(require("none-ls.formatting.jsonnetfmt").with({
                command = "${pkgs.go-jsonnet}/bin/jsonnetfmt",
              }))
            end
          '';
      };
    };
}
