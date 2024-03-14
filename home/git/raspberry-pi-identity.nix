{pkgs, ...}: {
  programs.git = {
    userName = "Benedikt Ritter";
    userEmail = "beneritter@gmail.com";
    signing = {
      signByDefault = true;
      key = "92166C2B83447076";
    };
  };
}
