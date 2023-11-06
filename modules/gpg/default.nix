{pkgs, ...}: {
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = pkgs.hostPlatform.isLinux;
    pinentryFlavor = "gnome3";
  };
}
