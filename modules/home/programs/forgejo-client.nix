_: {
  flake.modules.nixos.forgejo-client = {
    # git-credential-libsecret persists the Forgejo HTTPS token in the
    # gnome-keyring Secret Service (gated by polkit) across reboots
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
  };

  flake.modules.homeManager.forgejo-client =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.forgejo-cli ];
      # HTTPS auth for the self-hosted Forgejo (git.ritter.family). Scoped by
      # URL so it never touches the SSH-based GitHub/chainguard remotes.
      programs.git.settings.credential = {
        "https://git.ritter.family".helper = "${pkgs.gitFull}/bin/git-credential-libsecret";
        "https://codeberg.org".helper = "${pkgs.gitFull}/bin/git-credential-libsecret";
      };
    };
}
