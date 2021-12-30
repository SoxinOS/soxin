{ ... }@inputs:

rec {
  # TODO: Rename modules to types
  modules = import ./modules inputs;

  homeManagerConfiguration = import ./home-manager-configuration.nix inputs;
  mkSoxinModule = import ./mk-soxin-module.nix inputs;
  mkFlake = import ./mk-flake.nix inputs;
}
