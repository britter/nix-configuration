_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim = {
      plugins = {
        cmp_luasnip.enable = true;
        luasnip = {
          enable = true;
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
          action.__raw =
            # lua
            ''
              function()
                local ls = require "luasnip"
                if ls.expand_or_jumpable() then
                  ls.expand_or_jump()
                end
              end
            '';
          key = "<C-k>";
          mode = [
            "i"
            "s"
          ];
          options = {
            silent = true;
          };
        }
        {
          action.__raw =
            # lua
            ''
              function()
                local ls = require "luasnip"
                if ls.jumpable(-1) then
                  ls.jump(-1)
                end
              end
            '';
          key = "<C-j>";
          mode = [
            "i"
            "s"
          ];
          options = {
            silent = true;
          };
        }
      ];
    };
  };
}
