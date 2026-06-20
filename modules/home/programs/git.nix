_: {
  flake.modules.homeManager.git =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.git-absorb ];

      programs.git = {
        enable = true;

        settings = {
          user.name = config.user.fullName;
          user.email = config.user.email;

          init.defaultBranch = "main";
          push.autoSetupRemote = "true";
          merge.tool = "nvimdiff";
          merge.conflictstyle = "diff3";
          mergetool.keepBackup = "false";

          alias = {
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
        };

        signing = {
          signByDefault = true;
          format = "openpgp";
          key = config.user.signingKey;
        };

        # Person-level identity includes (email-only). Per-machine
        # signing-key overrides layer on top via module merging.
        includes = [
          {
            condition = "gitdir:~/github/britter/";
            contents.user.email = "beneritter@gmail.com";
          }
          {
            condition = "gitdir:~/github/gradlex-org/";
            contents.user.email = "benedikt@gradlex.org";
          }
          {
            condition = "gitdir:~/github/apache/";
            contents.user.email = "britter@apache.org";
          }
        ];
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          side-by-side = true;
          line-numbers = true;
        };
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
