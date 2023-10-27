{ pkgs, ... }:

{
  programs.git = {
    userName = "Benedikt Ritter";
    userEmail = "benedikt@gradle.com";
    signing = {
      signByDefault = true;
      key = "5AEF67FC9BD7F4CA";
    };
  };
}
