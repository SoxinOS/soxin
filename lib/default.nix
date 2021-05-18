{ lib, self, home-manager, ... }:

rec {
  homeManagerConfiguration = import ./home-manager-configuration.nix { inherit self lib home-manager; };
  mkSoxinModule = import ./mk-soxin-module.nix { inherit lib modules; };
  modules = import ./modules { inherit lib; };
  nixosSystem = import ./nixos-system.nix { inherit self lib home-manager; };
  overlaysToPkgs = import ./overlays-to-pkgs.nix { inherit lib; };
}
