_: {
  flake.modules.homeManager.nvim =
    { lib, pkgs, ... }:
    {
      programs.nixvim = {
        plugins.tmux-navigator.enable = true;

        # herdr's counterpart to tmux-navigator. The herdr side (keybindings and
        # plugin registration) lives in modules/home/ai-agents.nix.
        extraPlugins = [ pkgs.herdr-splits-nvim ];
        extraConfigLuaPost = ''
          -- Inside herdr, take over ctrl+hjkl from vim-tmux-navigator. Nested
          -- tmux keeps them: HERDR_ENV is inherited into a tmux pane, but there
          -- tmux owns the panes, so tmux-navigator must stay in charge.
          if vim.env.HERDR_ENV == "1" and not vim.env.TMUX then
            local hs = require("herdr-splits")
            hs.setup({ herdr_bin = "${lib.getExe pkgs.herdr}" })
            -- vim-tmux-navigator claims ctrl+hjkl from its own plugin/ directory,
            -- and Neovim sources a plugin's plugin/ files only after it has
            -- finished this config file. Mapping the keys right here would
            -- therefore be overwritten a moment later; VimEnter fires after both,
            -- so it is the first point where these mappings survive.
            vim.api.nvim_create_autocmd("VimEnter", {
              once = true,
              callback = function()
                for key, fn in pairs({
                  ["<C-h>"] = hs.move_cursor_left,
                  ["<C-j>"] = hs.move_cursor_down,
                  ["<C-k>"] = hs.move_cursor_up,
                  ["<C-l>"] = hs.move_cursor_right,
                }) do
                  vim.keymap.set("n", key, fn, { desc = "herdr-splits: navigate" })
                end
              end,
            })
          end
        '';

        keymaps = [
          {
            action = "<cmd>bdelete<CR>";
            key = "<leader>bd";
            mode = [ "n" ];
          }
          # Remap Crtl-d and Crtl-z to also center the view
          {
            action = "<C-d>zz";
            key = "<C-d>";
            mode = [ "n" ];
          }
          {
            action = "<C-u>zz";
            key = "<C-u>";
            mode = [ "n" ];
          }
          # Remap jumping trough search results to also center the view
          {
            action = "nzz";
            key = "n";
            mode = [ "n" ];
          }
          {
            action = "Nzz";
            key = "N";
            mode = [ "n" ];
          }
        ];
      };
    };
}
