{pkgs, ...}: {
  imports = [
    ../gnome
    ../firefox
    ../alacritty
  ];

  # software not available as Home Manager module
  home.packages = with pkgs; [
    jetbrains.idea-community
    fractal-next
  ];
}
