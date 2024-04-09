{
  pkgs-unstable,
  my-pkgs,
}: [
  (
    import
    ./packages-from-unstable
    {inherit pkgs-unstable;}
  )
  (import
    ./my-pkgs
    {inherit my-pkgs;})
]
