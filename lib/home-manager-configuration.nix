{ self, lib, home-manager }:

{ configuration
, system
, homeDirectory
, username
, modules ? [ ]
, hmSpecialArgs ? { }
, ...
} @ args:

home-manager.lib.homeManagerConfiguration (lib.recursiveUpdate (removeAttrs args [ "hmSpecialArgs" "modules" ]) {
  extraSpecialArgs = {
    mode = "home-manager";
    soxin = self;
  } // hmSpecialArgs;

  extraModules =
    (builtins.attrValues self.nixosModules)
    ++ modules;
})
