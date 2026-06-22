_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim.plugins = {
      # Review the configuration for cmp after switching to 24.11
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-n>" = "cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }";
            "<C-p>" = "cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }";
            "<C-y>" =
              # lua
              ''
                cmp.mapping(
                  cmp.mapping.confirm {
                    behavior = cmp.ConfirmBehavior.Insert,
                    select = true,
                  },
                  { "i", "c" }
                )
              '';
          };
          snippet.expand =
            # lua
            ''
              function(args)
                require('luasnip').lsp_expand(args.body)
              end
            '';
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "buffer"; }
          ];
        };
      };
    };
  };
}
