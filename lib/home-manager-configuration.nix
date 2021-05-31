# TODO: Get this merged into systemFlake

{ self, nixpkgs, home-manager }:


let
  inherit (nixpkgs) lib;
  inherit (lib) singleton removeAttrs recursiveUpdate;
in{
  # The configuration to build with home-manager.
  configuration

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

home-manager.lib.homeManagerConfiguration (recursiveUpdate (removeAttrs args [ "hmSpecialArgs" "hmModules" ]) {
  extraSpecialArgs = {
    mode = "home-manager";
    soxin = self;
  }
  # include the home-manager special arguments.
  // hmSpecialArgs;

  extraModules =
    # include the home-manager modules
    hmModules
    # include Soxin module
    ++ (singleton self.nixosModules.soxin);
})
