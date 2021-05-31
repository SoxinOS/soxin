{ self, nixpkgs, home-manager, ... }:

{
  # inputs of your own soxincfg
  inputs

  # The configuration to build with home-manager.
, configuration

  # The username and the absolute path to their home directory.
, username
, homeDirectory

  # What system to build for?
, system

  # Home-manager specific modules.
, hmModules ? [ ]

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

, ...
} @ args:

let
  inherit (builtins) removeAttrs;
  inherit (lib) singleton recursiveUpdate;
  inherit (nixpkgs) lib;

  otherArguments = removeAttrs args [
    "inputs"
    "hmSpecialArgs"
    "hmModules"
  ];

in
home-manager.lib.homeManagerConfiguration (recursiveUpdate
  {
    extraSpecialArgs = {
      inherit inputs;

      mode = "home-manager";
      soxin = self;
      soxincfg = inputs.self;
    }
    # include the home-manager special arguments.
    // hmSpecialArgs;

    extraModules =
      # include the home-manager modules
      hmModules
      # include Soxin module
      ++ (singleton self.nixosModules.soxin);
  }
  otherArguments)
