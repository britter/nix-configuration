{ pkgs, ... }:

{
  home.packages = with pkgs; [
    exa # ls replacement
    gradle
    nil # Nix lsp for helix
    taplo # TOML lsp for helix
    tldr # better man pages
  ];
  home.sessionVariables = {
    JDK8 = "${pkgs.jdk8}";
    # See below, this can be replaces with programs.helix.defaultEditor in the next home-manager release
    EDITOR = "hx";
  };

  programs.firefox.enable = true;

  programs.fish = {
    enable = true;

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "cat" = "bat";
      "ls" = "exa";
      "ll" = "exa -la";
    };

    shellInit = ''
      set -x LANG en_US.utf-8
      set -x MAVEN_OPTS "-Duser.name=benedikt"
      set -x GPG_TTY (tty)
    '';
  };

  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    disableConfirmationPrompt = true;
    sensibleOnTop = true;
    shell = "${pkgs.fish}/bin/fish";
    plugins = with pkgs; [
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = "set -g @catppuccin_flavor 'frappe'";
      }
    ];
    extraConfig = ''
      # Open new pane splits in CWD
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };

  programs.starship.enable = true; # prompt framework
  programs.bat.enable = true; # cat replacement
  programs.fzf.enable = true; # fuzzy finding
  programs.zoxide.enable = true; # smart cd replacement

  programs.git = {
    enable = true;

    userName = "Benedikt Ritter";
    userEmail = "beneritter@gmail.com";
    signing = {
      signByDefault = true;
      key = "394546A47BB40E12";
    };

    extraConfig = {
      init.defaultBranch = "main";
    };

    includes = [
      {
        condition = "gitdir:~/github/gradlex-org/";
        contents = {
          user.email = "benedikt@gradlex.org";
          user.signingKey = "757DE51A2FD1489D";
        };
      }
      {
        condition = "gitdir:~/github/apache/";
        contents = {
          user.email = "britter@apache.org";
          user.signingKey = "9DAADC1C9FCC82D0";
        };
      }
    ];

    aliases = {
      this = "!f() { git init && git add --all && git commit -m 'Initial commit'; }; f";
      tags = "tag -l";
      branches = "branch -a";
      remotes = "remote -v";
      lg = "log --all --graph --pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      cleanup = "!f() { git branch --merged main | grep -v main | xargs -n 1 git branch -D;  }; f";
      cleanup-deleted = "!git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D";
      sync = "!f() { git checkout main && git fetch upstream && git merge upstream/main && git push origin main && git cleanup && git fetch -p;  }; f";
      merge-back = "!f() { git fetch origin && git checkout release && git merge origin/release && git checkout main && git merge origin/main && git merge release && git cleanup-deleted;  }; f";
      co = "checkout";
      cm = "checkout main";
      st = "status";
      ci = "commit";
      cia = "commit --amend";
      rbi = "rebase --interactive main";
      rbm = "rebase main";
      rbc = "rebase --continue";
    };

    ignores = [
      ## IntelliJ stuff
      ".idea"
      "*.iml"
      "out/"

      ## Mac OS stuff
      ".DS_Store"
    ];

    diff-so-fancy.enable = true;
  };

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
