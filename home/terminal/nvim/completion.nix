_: {
  programs.nixvim = {
    plugins = {
      # Review the configuration for cmp after switching to 24.11
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-e>" = "cmp.mapping.close()";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
          snippet.expand =
            # lua
            ''
              function(args)
                require('luasnip').lsp_expand(args.body)
              end
            '';
          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "buffer";}
          ];
        };
      };
      cmp_luasnip.enable = true;
      luasnip = {
        enable = true;
        extraConfig = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
        fromLua = [
          {
            paths = ./snippets;
          }
        ];
      };
      friendly-snippets.enable = true;
    };
    keymaps = [
      {
        action.__raw = "function() require(\"luasnip\").jump(1) end";
        key = "<C-L>";
        mode = ["i" "s"];
        options = {
          silent = true;
        };
      }
      {
        action.__raw = "function() require(\"luasnip\").jump(-1) end";
        key = "<C-K>";
        mode = ["i" "s"];
        options = {
          silent = true;
        };
      }
    ];
  };
}
