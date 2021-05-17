{ self, lib, home-manager }:

with lib;

{ modules ? [ ], globalSpecialArgs ? { }, nixosSpecialArgs ? { }, hmSpecialArgs ? { }, ... } @ args:
nixosSystem (recursiveUpdate (removeAttrs args [ "globalSpecialArgs" "nixosSpecialArgs" "hmSpecialArgs" ]) {
  specialArgs = {
    mode = "NixOS";
    soxin = self;
  } // globalSpecialArgs // nixosSpecialArgs;

  modules =
    modules
    # include all Soxin modules
    ++ (builtins.attrValues self.nixosModules)
    # include all home-manager modules
    ++ (builtins.attrValues home-manager.nixosModules)
    # configure the arguments
    ++ (singleton {
      _module.args = { inherit home-manager; };
    })
    # configure home-manager
    ++ (singleton {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.extraSpecialArgs = {
        mode = "home-manager";
        soxin = self;
      }
      // globalSpecialArgs
      // hmSpecialArgs;

      home-manager.sharedModules = builtins.attrValues self.nixosModules;
    });
})
