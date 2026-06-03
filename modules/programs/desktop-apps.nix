{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        adwaita-icon-theme
        dconf
        evince
        file-roller
        gnome-calendar
        loupe
        nautilus
        qalculate-gtk
      ];

      xdg = {
        mime.enable = true;
        mimeApps = {
          enable = true;
          defaultApplications = {
            "application/pdf" = [ "org.gnome.Evince.desktop" ];
            "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
          };
        };
      };
    };
}
