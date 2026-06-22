_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim.colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "macchiato";
        term_colors = true;
        integrations = {
          treesitter = true;
          gitsigns = true;
          native_lsp.enabled = true;
          neotree = true;
        };
      };
    };
  };
}
