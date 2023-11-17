{pkgs, ...}: {
  programs.git = {
    enable = true;

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
