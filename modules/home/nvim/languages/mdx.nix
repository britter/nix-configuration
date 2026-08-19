_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim = {
      filetype.extension.mdx = "mdx";
      plugins.treesitter.languageRegister.markdown = "mdx";
      extraFiles."after/queries/markdown/injections.scm".text =
        # scheme
        ''
          ; extends
          ((inline) @injection.content
            (#lua-match? @injection.content "^%s*import")
            (#set! injection.language "typescript"))
          ((inline) @injection.content
            (#lua-match? @injection.content "^%s*export")
            (#set! injection.language "typescript"))
        '';
    };
  };
}
