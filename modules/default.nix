{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common-utilities
    ./disko
    ./i18n
  ];
}
