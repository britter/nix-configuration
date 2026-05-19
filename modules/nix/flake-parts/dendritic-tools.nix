{
  inputs,
  ...
}:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  # set flake.systems
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
