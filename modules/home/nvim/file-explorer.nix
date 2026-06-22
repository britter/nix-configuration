_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim = {
      plugins = {
        neo-tree.enable = true;
        oil = {
          enable = true;
          settings.skip_confirm_for_simple_edits = true;
        };
      };
      keymaps = [
        {
          action = "<cmd>Neotree filesystem reveal toggle left<CR>";
          key = "<C-n>";
          mode = [ "n" ];
        }
        {
          action = "<cmd>Oil<CR>";
          key = "-";
          mode = [ "n" ];
        }
      ];
    };
  };
}
