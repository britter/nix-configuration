_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim = {
      opts = {
        # Set tab width to 4 spaces (instead of 8)
        tabstop = 4;
        # Set how many spaces will be inserted when tab is pressed
        softtabstop = 2;
        showtabline = 2;
        expandtab = true;

        # Enable auto indenting and set it to spaces
        smartindent = true;
        shiftwidth = 2;

        # Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
        breakindent = true;

        swapfile = false;

        number = true;
        relativenumber = true;

        # Enable 24-bit colors
        termguicolors = true;

        # Enable the sign column to prevent the screen from jumping
        signcolumn = "yes";

        # Highlight cursor line
        cursorline = true;

        # Remaining lines visibile before starting to scroll
        scrolloff = 5;

        list = true;
        listchars = "tab:→·,lead:·,space:·,trail:~,extends:→,precedes:←,nbsp:␣";
      };
      # Show diagnostic as a virtual line but only below the current cursor line
      diagnostic.settings.virtual_lines.current_line = true;
      plugins = {
        nvim-surround.enable = true;
        sleuth.enable = true;
      };
      # Auto-sourced at startup because it lands in nvim's plugin/ dir
      extraFiles."plugin/unescape.lua".source = ./lua/unescape.lua;
      keymaps = [
        {
          action = "<cmd>split<CR>";
          key = ''<leader>"'';
          mode = [ "n" ];
        }
        {
          action = "<cmd>vsplit<CR>";
          key = "<leader>%";
          mode = [ "n" ];
        }
      ];
    };
  };
}
