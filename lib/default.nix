{ self, home-manager, utils, nixpkgs, ... }@inputs:

rec {
  mkSoxinModule = import ./mk-soxin-module.nix inputs;
  modules = import ./modules inputs;
  systemFlake = import ./system-flake.nix inputs;
}
