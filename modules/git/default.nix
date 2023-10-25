{ pkgs, ... }:

{
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
}
