{ self, lib, home-manager }:

with lib;

{
  # The global modules are included in both NixOS and home-manager.
  globalModules ? [ ]

  # Home-manager specific modules.
, hmModules ? [ ]

  # NixOS specific modules.
, nixosModules ? [ ]

  # The global extra arguments are included in both NixOS and home-manager.
, globalSpecialArgs ? { }

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

  # NixOS specific extra arguments.
, nixosSpecialArgs ? { }

, ...
} @ args:
let
  args' = removeAttrs args [
    "globalModules"
    "nixosModules"
    "hmModules"

    "globalSpecialArgs"
    "nixosSpecialArgs"
    "hmSpecialArgs"
  ];
in
nixosSystem (recursiveUpdate args' {
  specialArgs = {
    # send home-manager down to the NixOS modules
    inherit home-manager;

    # the mode allows us to tell at what level we are within the modules.
    mode = "NixOS";

    # send soxin to all NixOS modules
    soxin = self;
  }
  # include the global special arguments.
  // globalSpecialArgs
  # include the NixOS special arguments.
  // nixosSpecialArgs;

  modules =
    # include the global modules
    globalModules
    # include the NixOS modules
    ++ nixosModules
    # include all Soxin modules
    ++ (builtins.attrValues self.nixosModules)
    # include all home-manager modules
    ++ (builtins.attrValues home-manager.nixosModules)
    # configure Nix registry so users can find soxin
    ++ singleton { nix.registry.soxin.flake = self; }
    # configure home-manager
    ++ (singleton {
      # tell home-manager to use the global (as in NixOS system-level) pkgs and
      # install all  user packages through the users.users.<name>.packages.
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.extraSpecialArgs = {
        # send home-manager down to the home-manager modules
        inherit home-manager;

        # the mode allows us to tell at what level we are within the modules.
        mode = "home-manager";
        # send soxin to all NixOS modules
        soxin = self;
      }
      # include the global special arguments.
      // globalSpecialArgs
      # include the NixOS special arguments.
      // hmSpecialArgs;

      home-manager.sharedModules =
        # include the global modules
        globalModules
        # include the home-manager modules
        ++ hmModules
        # include all Soxin modules
        ++ (builtins.attrValues self.nixosModules);
    });
})
