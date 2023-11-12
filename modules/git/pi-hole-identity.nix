{pkgs, ...}: {
  programs.git = {
    userName = "Benedikt Ritter";
    userEmail = "beneritter@gmail.com";
    signing = {
      signByDefault = true;
      key = "0xD4E542B865647985";
    };
  };
}
