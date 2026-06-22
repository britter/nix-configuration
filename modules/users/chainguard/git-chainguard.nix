_: {
  flake.modules.homeManager.git-chainguard =
    { config, pkgs, ... }:
    {
      programs.git.ignores = [ ".claude/settings.local.json" ];

      programs.git.includes = [
        # gradlex per-machine signing key (benedikt's chainguard-laptop openpgp key)
        {
          condition = "gitdir:~/github/gradlex-org/";
          contents.user.signingKey = "6C9C4BE5D6A7FCCC";
        }
        # chainguard scoped gitsign x509
        {
          condition = "gitdir:~/github/chainguard-dev/";
          contents = {
            user.email = "benedikt.ritter@chainguard.dev";
            gpg.format = "x509";
            gpg.x509.program = "${pkgs.gitsign}/bin/gitsign";
            gitsign.connectorID = "https://accounts.google.com";
          };
        }
      ];

      home.sessionVariables.GITSIGN_CREDENTIAL_CACHE = "${config.home.homeDirectory}/.cache/sigstore/gitsign/cache.sock";

      # Socket-activated: only the .socket is enabled. systemd binds cache.sock at
      # boot and starts the daemon on first connect, passing the listener via
      # LISTEN_FDS. The --systemd-socket-activation flag is required for the
      # daemon to use that listener instead of creating (and clobbering) its own.
      systemd.user = {
        enable = true;
        services.gitsign-credential-cache = {
          Unit.Description = "GitSign credential cache";
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.gitsign}/bin/gitsign-credential-cache --systemd-socket-activation";
          };
        };
        sockets.gitsign-credential-cache = {
          Unit.Description = "GitSign credential cache socket";
          Socket = {
            ListenStream = "%C/sigstore/gitsign/cache.sock";
            DirectoryMode = "0700";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
