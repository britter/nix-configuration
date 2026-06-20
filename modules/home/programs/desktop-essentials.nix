_: {
  flake.modules.homeManager.desktop-essentials =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        audacity
        chromium
        gimp
        libreoffice
        vlc
      ];
    };
}
