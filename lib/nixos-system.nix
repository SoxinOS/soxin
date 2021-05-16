{ self, lib, home-manager }:

{ modules ? [ ], globalSpecialArgs ? { }, nixosSpecialArgs ? { }, hmSpecialArgs ? { }, ... } @ args:
lib.nixosSystem (lib.recursiveUpdate (removeAttrs args [ "globalSpecialArgs" "nixosSpecialArgs" "hmSpecialArgs" ]) {
  specialArgs = {
    mode = "NixOS";
    soxin = self;
  } // globalSpecialArgs // nixosSpecialArgs;

  modules =
    modules
    ++ (builtins.attrValues self.nixosModules)
    ++ (builtins.attrValues home-manager.nixosModules)
    ++ [
      {
        _module.args = { inherit home-manager; };
      }

      # Required when using flakes.
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }

      # Override home-manager per-user submodule to add our own modules to it,
      # and to pass the argument `mode`.
      ({ config, ... }: {
        options.home-manager.users = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submoduleWith {
            modules =
              (builtins.attrValues self.nixosModules)
              ++ [{ _module.args = { inherit home-manager; }; }];

            specialArgs = {
              mode = "home-manager";
              soxin = self;
            }
            // globalSpecialArgs
            // hmSpecialArgs;
          });
        };
      })
    ];
})
