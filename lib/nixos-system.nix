{ self, lib, home-manager }:

{ modules ? [], specialArgs ? { }, ... } @ args:
lib.nixosSystem (args // {
  specialArgs = lib.mergeAttrs {
    mode = "NixOS";
  } specialArgs;

  modules = lib.concat [
    self.nixosModules.soxin

    home-manager.nixosModules.home-manager
    {
      # This is required when using flakes.
      home-manager.useGlobalPkgs = true;
    }

    # Allow accessing the parent NixOS configuration.
    ({ config, ... }: {
      options.home-manager.users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submoduleWith {
          modules = [
            self.nixosModules.soxin
          ];
          specialArgs = {
            super = config;
            mode = "home-manager";
          };
        });
      };
    })
  ] modules;
})