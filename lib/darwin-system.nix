{ self, lib, darwin, home-manager }:

with lib;

{
  # The global modules are included in both Darwin and home-manager.
  globalModules ? [ ]

  # Darwin specific modules.
, darwinModules ? [ ]

  # Home-manager specific modules.
, hmModules ? [ ]

  # The global extra arguments are included in both Darwin and home-manager.
, globalSpecialArgs ? { }

  # Darwin specific extra arguments.
, darwinSpecialArgs ? { }

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

, ...
} @ args:
let
  args' = removeAttrs args [
    "globalModules"
    "darwinModules"
    "hmModules"

    "globalSpecialArgs"
    "darwinSpecialArgs"
    "hmSpecialArgs"
  ];
in
darwin.lib.darwinSystem (recursiveUpdate args' {
  specialArgs = {
    # send home-manager down to the Darwin modules
    inherit home-manager;

    # the mode allows us to tell at what level we are within the modules.
    mode = "Darwin";

    # send soxin down to NixOS.
    soxin = self;
  }
  # include the global special arguments.
  // globalSpecialArgs
  # include the NixOS special arguments.
  // darwinSpecialArgs;

  modules =
    # include the global modules
    globalModules
    # include the Darwin modules
    ++ darwinModules
    # include Soxin modules
    ++ (singleton self.darwinModule)
    # include home-manager modules
    ++ (singleton home-manager.darwinModules.home-manager)
    # configure Nix registry so users can find soxin
    ++ singleton { nix.registry.soxin.flake = self; }
    # configure home-manager
    ++ (singleton {
      # tell home-manager to use the global (as in Darwin system-level) pkgs
      # and install all user packages through the users.users.<name>.packages.
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.extraSpecialArgs = {
        # send home-manager down to the home-manager modules
        inherit home-manager;

        # the mode allows us to tell at what level we are within the modules.
        mode = "home-manager";
        # send soxin down to home-manager.
        soxin = self;
      }
      # include the global special arguments.
      // globalSpecialArgs
      # include the home-manager special arguments.
      // hmSpecialArgs;

      home-manager.sharedModules =
        # include the global modules
        globalModules
        # include the home-manager modules
        ++ hmModules
        # include Soxin module
        ++ (singleton self.nixosModule);
    });
})
