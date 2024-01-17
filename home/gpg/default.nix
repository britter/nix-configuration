{pkgs, ...}: {
  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        # personal key
        source = ./394546A47BB40E12.pub;
        trust = 5;
      }
      {
        # Apache code signing key
        source = ./9DAADC1C9FCC82D0.pub;
        trust = 5;
      }
      {
        # GradleX code signing key
        source = ./757DE51A2FD1489D.pub;
        trust = 5;
      }
      {
        # GradleX release signing key
        source = ./FE6C7D77A1CE15A6.pub;
        trust = 4;
      }
    ];
  };
  services.gpg-agent = {
    enable = pkgs.hostPlatform.isLinux;
    pinentryFlavor = "gnome3";
  };
}
