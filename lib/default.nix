{ ... }@inputs:

rec {
  # TODO: Rename modules to types
  modules = import ./modules inputs;

  homeManagerConfiguration = import ./home-manager-configuration.nix inputs;
  mkSoxinModule = import ./mk-soxin-module.nix inputs;
  systemFlake = import ./system-flake.nix inputs;
}
