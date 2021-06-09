inputs@{ soxin, nixpkgs, ... }:

{
  minimal-home = {
    configuration = ./minimal-home/home.nix;
    username = "nick";
    homeDirectory = "/home/nick";
    system = "x86_64-linux";
  };
}
