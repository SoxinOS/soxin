{
  soxin,
  config,
  lib,
  ...
}:

with lib;
{
  imports = [
    ./keyboard.nix
    ./programming-languages.nix
    ./theme.nix
    ./tools.nix
  ];
}
