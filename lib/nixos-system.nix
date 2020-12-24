{ self, lib, home-manager }:

{ modules ? [ ], specialArgs ? { }, ... } @ args:
lib.nixosSystem (args // {
  specialArgs = lib.mergeAttrs
    {
      mode = "NixOS";
      inherit home-manager;
    }
    specialArgs;

  modules = modules ++ [
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
            self.nixosModules.soxin
          ];
          specialArgs = {
            mode = "home-manager";
            inherit home-manager;
          };
        });
      };
    })
  ];
})
