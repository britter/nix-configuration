{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.my.home.terminal.git;
  osUser = osConfig.my.user;
in
{
  options.my.home.terminal.git = {
    enable = lib.mkEnableOption "git";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.git-absorb ];

    programs.git = {
      enable = true;

      userName = osUser.fullName;
      userEmail = osUser.email;

      signing = {
        signByDefault = true;
        key = osUser.signingKey;
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
        {
          condition = "gitdir:~/clients/";
          contents = {
            user.email = "benedikt.ritter@proton.me";
            user.signingKey = "F9190A44AEFC562C";
          };
        }
      ];

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = "true";
      };

      aliases = {
        this = "!f() { git init && git add --all && git commit -m 'Initial commit'; }; f";
        tags = "tag -l";
        branches = "branch -a";
        remotes = "remote -v";
        lg = "log --all --graph --pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        cleanup = "!f() { git branch --merged main | grep -v main | xargs -n 1 git branch -D;  }; f";
        cleanup-deleted = "!git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D";
        sync = "!f() { git checkout main && git fetch upstream && git merge upstream/main && git push origin main && git cleanup && git fetch -p;  }; f";
        co = "checkout";
        cm = "checkout main";
        st = "status";
        ci = "commit";
        cia = "commit --amend";
        rbi = "rebase --interactive main";
        rbm = "rebase main";
        rbc = "rebase --continue";
      };

      diff-so-fancy.enable = true;
    };

    programs.lazygit = {
      enable = true;
      # Config reference: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
      settings = {
        promptToReturnFromSubprocess = false;
      };
    };
  };
}
