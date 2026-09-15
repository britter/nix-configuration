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
            # Resolve a remote's default branch instead of assuming "main".
            # Takes the remote as an argument (default: origin) and prefers
            # <remote>/HEAD, which git writes at clone time and never
            # refreshes on fetch -- run `git remote set-head <remote> -a`
            # after the remote renames its default branch. Falls back to
            # whichever of main/master exists, then to main.
            default-branch = "!f() { r=\"\${1:-origin}\"; b=$(git symbolic-ref --quiet --short \"refs/remotes/$r/HEAD\" 2>/dev/null | sed \"s|^$r/||\"); if [ -z \"$b\" ]; then for c in main master; do if git show-ref --verify --quiet \"refs/remotes/$r/$c\" || git show-ref --verify --quiet \"refs/heads/$c\"; then b=$c; break; fi; done; fi; if [ -z \"$b\" ]; then b=main; fi; echo \"$b\"; }; f";
            cleanup = "!f() { b=$(git default-branch); git branch --merged \"$b\" --format='%(refname:short)' | grep -vx \"$b\" | xargs -r -n 1 git branch -D;  }; f";
            cleanup-deleted = "!git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D";
            # In a fork the branch to merge is upstream's default, which can
            # differ from the fork's own (e.g. upstream renamed master to
            # main and the fork did not). Without an upstream remote this
            # degrades to syncing the default branch against origin.
            sync = "!f() { r=upstream; git remote get-url upstream >/dev/null 2>&1 || r=origin; o=$(git default-branch origin); git checkout \"$o\" && git fetch \"$r\" && u=$(git default-branch \"$r\") && { git show-ref --verify --quiet \"refs/remotes/$r/$u\" || u=\"$o\"; } && git merge \"$r/$u\" && git push origin \"$o\" && git cleanup && git fetch -p;  }; f";
            co = "checkout";
            cm = "!f() { git checkout \"$(git default-branch)\"; }; f";
            st = "status";
            ci = "commit";
            cia = "commit --amend";
            rbi = "!f() { git rebase --interactive \"$(git default-branch)\"; }; f";
            rbm = "!f() { git rebase \"$(git default-branch)\"; }; f";
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

      programs.lazygit = {
        enable = true;
        # Config reference: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
        settings = {
          promptToReturnFromSubprocess = false;
        };
      };
    };
}
