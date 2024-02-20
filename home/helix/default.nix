{pkgs, ...}: let
  nvim-treesitter = pkgs.fetchFromGitHub {
    owner = "nvim-treesitter";
    repo = "nvm-treesitter";
    rev = "f75a5b4e144228e4b2ab3006ed167b6fe37d0b33";
    sha256 = "sha256-I5Dc80BgyCdnN3nMzCFEURsQL/gaudgJLfjH+HWpK+s=";
  };
in {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      jdt-language-server # Eclipse JDT language server
      kotlin-language-server
      nil # Nix lsp
      taplo # TOML lsp
    ];
    settings = {
      theme = "catppuccin_macchiato";
      editor.file-picker = {
        hidden = false;
      };
      editor.whitespace.render = {
        space = "all";
        nbsp = "all";
        tab = "all";
      };
      keys.normal = {
        up = "no_op";
        down = "no_op";
        left = "no_op";
        right = "no_op";
        pageup = "no_op";
        pagedown = "no_op";
      };
    };
    languages = {
      language-server.groovy = {
        command = "${pkgs.groovy-language-server}/bin/groovy-language-server";
      };
      language = [
        {
          name = "groovy";
          language-id = "groovy";
          scope = "source.groovy";
          injection-regex = "groovy";
          file-types = ["groovy" "gradle" "Jenkinsfile"];
          shebangs = ["groovy"];
          roots = ["build.gradle" "build.gradle.kts" "settings.gradle" "settings.gradle.kts" "pom.xml"];
          comment-token = "//";
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          language-servers = ["groovy"];
        }
      ];
      grammar = [
        {
          name = "groovy";
          source = {
            git = "https://github.com/murtaza64/tree-sitter-groovy";
            rev = "235009aad0f580211fc12014bb0846c3910130c1";
          };
        }
      ];
    };
  };
  xdg.configFile."helix/runtime/queries/groovy".source = "${nvim-treesitter}/queries/groovy";
}
