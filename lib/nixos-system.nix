{ self, lib, home-manager }:

{ modules ? [ ], globalSpecialArgs ? { }, nixosSpecialArgs ? { }, hmSpecialArgs ? { }, ... } @ args:
lib.nixosSystem (lib.recursiveUpdate (removeAttrs args [ "globalSpecialArgs" "nixosSpecialArgs" "hmSpecialArgs" ]) {
  specialArgs = { mode = "NixOS"; } // globalSpecialArgs // nixosSpecialArgs;

  modules = modules ++ [
    {
      _module.args = { inherit home-manager; };
    }

    self.nixosModules.soxin

    home-manager.nixosModules.home-manager
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
          modules = [
            {
              _module.args = { inherit home-manager; };
            }
            self.nixosModules.soxin
          ];
          specialArgs = { mode = "home-manager"; } // globalSpecialArgs // hmSpecialArgs;
        });
      };
    })
  ];
})
