_: {
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    {
      programs.nixvim = {
        # No nixvim module for this plugin; it comes pre-packaged from nixpkgs
        # (vimPlugins.md-table-tidy-nvim), so wire it in via extraPlugins.
        extraPlugins = [ pkgs.vimPlugins.md-table-tidy-nvim ];
        extraConfigLuaPost = ''
          -- The plugin's default keymaps (<leader>tt/<leader>ta) are disabled; use
          -- the :TableTidy / :TableTidyAll commands instead.
          require("md-table-tidy").setup({
            keymap = {
              table_tidy = false,
              table_tidy_all = false,
            },
          })
        '';
      };
    };
}
