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
        gnome-text-editor
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
            "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
            "image/png" = [ "org.gnome.Loupe.desktop" ];
            "image/gif" = [ "org.gnome.Loupe.desktop" ];
            "image/webp" = [ "org.gnome.Loupe.desktop" ];
            "image/avif" = [ "org.gnome.Loupe.desktop" ];
            "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
            "text/plain" = [ "org.gnome.TextEditor.desktop" ];
            "text/csv" = [ "org.gnome.TextEditor.desktop" ];
            "text/markdown" = [ "org.gnome.TextEditor.desktop" ];
            "application/json" = [ "org.gnome.TextEditor.desktop" ];
            "video/mp4" = [ "vlc.desktop" ];
            "video/mpeg" = [ "vlc.desktop" ];
            "video/webm" = [ "vlc.desktop" ];
            "video/x-matroska" = [ "vlc.desktop" ];
            "video/quicktime" = [ "vlc.desktop" ];
            "video/x-msvideo" = [ "vlc.desktop" ];
            "audio/mpeg" = [ "vlc.desktop" ];
            "audio/flac" = [ "vlc.desktop" ];
            "audio/x-wav" = [ "vlc.desktop" ];
            "audio/ogg" = [ "vlc.desktop" ];
            "audio/aac" = [ "vlc.desktop" ];
            "audio/x-m4a" = [ "vlc.desktop" ];
            "image/heic" = [ "org.gnome.Loupe.desktop" ];
            "application/epub+zip" = [ "org.gnome.Evince.desktop" ];
            "application/zip" = [ "org.gnome.FileRoller.desktop" ];
            "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
            "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
            "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
            "application/x-zstd-compressed" = [ "org.gnome.FileRoller.desktop" ];
          };
        };
      };
    };
}
