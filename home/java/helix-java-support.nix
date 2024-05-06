{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.helix-java-support;
  helix-unstable = pkgs.fetchFromGitHub {
    owner = "helix-editor";
    repo = "helix";
    rev = "2e4653ea312dcb69d2453eccaa7c0f873cce6aa5";
    sha256 = "sha256-MShFz1lc6eAEcJx4jk9TC571pDNHFJGkkUmmmaXmVtQ=";
  };
in {
  options.my.home.helix-java-support = {
    enable = lib.mkEnableOption "helix-java-support";
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      extraPackages = with pkgs; [
        jdt-language-server # Eclipse JDT language server
        kotlin-language-server
      ];
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
    xdg.configFile."helix/runtime/queries/groovy".source = "${helix-unstable}/runtime/queries/groovy";
  };
}
