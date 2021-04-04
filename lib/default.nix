{ lib, self, home-manager, ... }:

{
  modules = import ./modules { inherit lib; };
  nixosSystem = import ./nixos-system.nix {
    inherit self lib home-manager;
  };
  overlaysToPkgs = import ./overlays-to-pkgs.nix { inherit lib; };
}
