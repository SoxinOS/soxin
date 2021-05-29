{ lib, self, home-manager, utils, ... }:

rec {
  mkSoxinModule = import ./mk-soxin-module.nix { inherit lib modules; };
  modules = import ./modules { inherit lib; };
  systemFlake = import ./system-flake.nix { inherit home-manager lib modules utils; };
}
