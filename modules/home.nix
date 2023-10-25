{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gradle
    nil # Nix lsp for helix
    taplo # TOML lsp for helix
  ];
  home.sessionVariables = {
    JDK8 = "${pkgs.jdk8}";
    # See below, this can be replaces with programs.helix.defaultEditor in the next home-manager release
    EDITOR = "hx";
  };

  imports = [
    ./git
    ./terminal
  ];

  programs.firefox.enable = true;

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "gnome3";
  };

  programs.gh = {
    enable = true;

    extensions =
      let
        gh-get = with pkgs; stdenv.mkDerivation rec {
          name = "gh-get";
          pname = "gh-get";
          src = fetchFromGitHub {
            owner = "britter";
            repo = "gh-get";
            rev = "v1.0.0";
            sha256 = "sha256-2o7Ugi8Ba3rso68Onc8tuh/RzWxZ9OTkdJYgo3K6+Gs=";
          };

          installPhase = ''
            mkdir -p $out/bin
            cp gh-get $out/bin
          '';
          };
      in
      [ gh-get ];
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };

  programs.helix = {
    enable = true;
    # defaultEditor is a setting in home-manager master. Comment out once updated to next home-manager release
    # defaultEditor = true;
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
  };
}
