{ self, nixpkgs, home-manager, ... }:

{
  # inputs of your own soxincfg
  inputs

# TODO: comment
, pkgs

  # Home-manager specific modules.
, modules ? [ ]

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

, ...
} @ args:

let
  inherit (builtins) removeAttrs;
  inherit (lib) singleton recursiveUpdate;
  inherit (nixpkgs) lib;

  soxin = self;
  soxincfg = inputs.self;

  otherArguments = removeAttrs args [
    "inputs"
    "hmSpecialArgs"
  ];

in
home-manager.lib.homeManagerConfiguration (recursiveUpdate
{
  extraSpecialArgs = {
    inherit inputs soxin soxincfg;

    mode = "home-manager";
  }
  # include the home-manager special arguments.
  // hmSpecialArgs;

  modules =
    # include Soxin module
    (singleton soxin.nixosModules.soxin)
    # include SoxinCFG module
    ++ (singleton soxincfg.nixosModules.soxincfg);
}
  otherArguments)
