_: {
  flake.modules.homeManager.nvim =
    { lib, pkgs, ... }:
    {
      programs.nixvim = {
        plugins.telescope = {
          enable = true;
          extensions.ui-select.enable = true;
          extensions.fzf-native.enable = true;
          settings =
            let
              rgArgs = [
                "--hidden"
                "--glob"
                "!**/.git/*"
              ];
            in
            {
              defaults = {
                vimgrep_arguments = [
                  (lib.getExe pkgs.ripgrep)
                  "--color=never"
                  "--no-heading"
                  "--with-filename"
                  "--line-number"
                  "--column"
                  "--smart-case"
                ]
                ++ rgArgs;
              };
              pickers.find_files.find_command = [
                (lib.getExe pkgs.ripgrep)
                "--files"
              ]
              ++ rgArgs;
            };
        };
        keymaps = [
          {
            action = "<cmd>Telescope find_files<CR>";
            key = "<leader>ff";
            mode = [ "n" ];
          }
          {
            action = "<cmd>Telescope live_grep<CR>";
            key = "<leader>fg";
            mode = [ "n" ];
          }
          {
            action = "<cmd>Telescope buffers<CR>";
            key = "<leader>fb";
            mode = [ "n" ];
          }
          {
            action = "<cmd>Telescope help_tags<CR>";
            key = "<leader>fh";
            mode = [ "n" ];
          }
        ];
      };
    };
}
