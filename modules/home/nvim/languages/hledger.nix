_: {
  flake.modules.homeManager.nvim =
    { lib, pkgs, ... }:
    {
      programs.nixvim.plugins.none-ls.luaConfig.post =
        # lua
        ''
          do
            local null_ls = require("null-ls")
            null_ls.register({
              name = "hledger_fmt",
              method = null_ls.methods.FORMATTING,
              filetypes = { "ledger", "hledger" },
              generator = require("null-ls.helpers").formatter_factory({
                command = "${lib.getExe pkgs.hledger-fmt}",
                args = { "-", "--no-diff", "--exit-zero-on-changes" },
                to_stdin = true,
              }),
            })
          end
        '';
    };
}
