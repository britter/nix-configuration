{
  lib,
  ...
}:
let
  appPkgs =
    pkgs: with pkgs; [
      adwaita-icon-theme
      dconf
      evince
      file-roller
      gnome-calendar
      gnome-text-editor
      loupe
      nautilus
      qalculate-gtk
      vlc
    ];

  # desktop file -> associated mime types
  associations = {
    "org.gnome.Evince.desktop" = [
      "application/pdf"
      "application/epub+zip"
    ];
    "org.gnome.Nautilus.desktop" = [ "inode/directory" ];
    "org.gnome.Loupe.desktop" = [
      "image/jpeg"
      "image/png"
      "image/gif"
      "image/webp"
      "image/avif"
      "image/svg+xml"
      "image/heic"
    ];
    "org.gnome.TextEditor.desktop" = [
      "text/plain"
      "text/csv"
      "text/markdown"
      "application/json"
    ];
    "vlc.desktop" = [
      "video/mp4"
      "video/mpeg"
      "video/webm"
      "video/x-matroska"
      "video/quicktime"
      "video/x-msvideo"
      "audio/mpeg"
      "audio/flac"
      "audio/x-wav"
      "audio/ogg"
      "audio/aac"
      "audio/x-m4a"
    ];
    "org.gnome.FileRoller.desktop" = [
      "application/zip"
      "application/x-tar"
      "application/gzip"
      "application/x-7z-compressed"
      "application/x-zstd-compressed"
    ];
  };

  mimeApps = lib.concatMapAttrs (
    desktop: mimes: lib.listToAttrs (map (mime: lib.nameValuePair mime [ desktop ]) mimes)
  ) associations;

  # Fails the check if an associated desktop file isn't shipped by appPkgs.
  mimeCheck =
    pkgs:
    pkgs.runCommand "mime-associations-check"
      {
        appsEnv = pkgs.buildEnv {
          name = "desktop-apps-check-env";
          paths = appPkgs pkgs;
          pathsToLink = [ "/share/applications" ];
        };
        desktops = lib.concatStringsSep " " (builtins.attrNames associations);
      }
      ''
        for d in $desktops; do
          test -e "$appsEnv/share/applications/$d" || {
            echo "missing desktop file for a file association: $d" >&2
            exit 1
          }
        done
        touch $out
      '';
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.mime-associations = mimeCheck pkgs;
    };

  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = appPkgs pkgs;

      xdg = {
        mime.enable = true;
        mimeApps = {
          enable = true;
          defaultApplications = mimeApps;
        };
      };
    };
}
