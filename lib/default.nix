{ lib, self, home-manager, ... }:

{
  mkSoxinModule = import ./mk-soxin-module.nix { inherit lib; };

  nixosSystem = import ./nixos-system.nix {
    inherit self lib home-manager;
  };

  overlaysToPkgs = import ./overlays-to-pkgs.nix { inherit lib; };
}
