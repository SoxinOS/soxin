{ self, lib, home-manager }:

{ modules ? [], system, ... }@args:
lib.nixosSystem {
  inherit system;
  modules = modules ++ [ self.nixosModules.soxin home-manager.nixosModules.home-manager ];
}
