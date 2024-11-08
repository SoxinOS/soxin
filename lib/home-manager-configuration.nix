{ self, nixpkgs, home-manager, ... }:

{
  # inputs of your own soxincfg
  inputs

  # Home-manager specific modules.
, modules ? [ ]

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

  # What packages to use?
, pkgs ? inputs.nixpkgs.legacyPackages."${system}"

  # What system to build for?
, system

, ...
} @ args:

let
  inherit (builtins) removeAttrs;
  inherit (lib) singleton recursiveUpdate;
  inherit (nixpkgs) lib;

  soxin = self;
  soxincfg = inputs.self;

  otherArguments = removeAttrs args [
    "hmSpecialArgs"
    "inputs"
    "modules"
    "pkgs"
    "system"
  ];

  hmArgs = (recursiveUpdate
    {
      inherit pkgs;

      extraSpecialArgs = {
        inherit inputs soxin soxincfg;

        mode = "home-manager";
      }
      # include the home-manager special arguments.
      // hmSpecialArgs;

      modules =
        modules
        # include Soxin module
        ++ (singleton soxin.nixosModules.soxin)
        # include SoxinCFG module
        ++ (singleton soxincfg.nixosModules.soxincfg);
    }
    otherArguments);
in
home-manager.lib.homeManagerConfiguration hmArgs
