{ self, lib, home-manager }:

{ modules ? [], ... } @ args:
lib.nixosSystem (args // {
  modules = lib.concat modules [
    home-manager.nixosModules.home-manager
  ];
})
