_: {
  # bitwarden-desktop ships with an outdated electron
  flake.permittedInsecurePackages = [ "electron-39.8.10" ];

  flake.modules.homeManager.bitwarden =
    { config, pkgs, ... }:
    {
      home.packages = [
        pkgs.bitwarden-desktop
      ];

      # `rbw` for scripts: agent-based, no session env var to export.
      programs.rbw = {
        enable = true;
        settings = {
          email = config.user.email;
          base_url = "https://passwords.ritter.family";
          pinentry = pkgs.pinentry-gnome3;
        };
      };
    };
}
