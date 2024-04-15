{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./1password
    ./common-utilities
    ./disko
    ./i18n
  ];
}
