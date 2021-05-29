{ home-manager, lib, modules, utils }:

# TODO

{
  # inputs of your own soxincfg
  inputs

  # self should be your own soxincfg
, self

  # attr attribute set of hosts
  # See https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/e7ae270a23695b50fbb6b72759a7fb1e3340ca86/examples/fully-featured/flake.nix#L101-L112
, hosts

  # The global modules are included in both NixOS and home-manager.
, globalModules ? [ ]

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
  inherit (lib) mapAttrs recursiveUpdate singleton;
  inherit (builtins) removeAttrs;

  otherArguments = removeAttrs args [
    "inputs"
    "self"
    "hosts"

    "globalModules"
    "hmModules"
    "nixosModules"

    "globalSpecialArgs"
    "hmSpecialArgs"
    "nixosSpecialArgs"
  ];

  hosts' = mapAttrs
    (hostname: configuration: (recursiveUpdate [
      # inject the special args
      {
        specialArgs = {
          # send home-manager down to the NixOS modules
          inherit home-manager;

          # the mode allows us to tell at what level we are within the modules.
          mode = "NixOS";

          # send soxin down to NixOS.
          soxin = self;
        }
        # include the global special arguments.
        // globalSpecialArgs
        # include the NixOS special arguments.
        // nixosSpecialArgs;
      }

      # pass along the passed-in configuration
      configuration
    ]))
    hosts;
in
utils.lib.systemFlake (recursiveUpdate [
  # inherit the required fields as-is
  { inherit self inputs utils; }

  # set the hosts
  { hosts = hosts'; }

  # configure the modules
  {
    hostDefaults.modules =
      # include the global modules
      globalModules
      # include sane flake defaults from utils which sets sane `nix.*` defaults.
      # Please refer to implementation/readme in
      # github:gytis-ivaskevicius/flake-utils-plus for more details.
      ++ (singleton utils.nixosModules.saneFlakeDefaults)
      # include the NixOS modules
      ++ nixosModules
      # include Soxin modules
      ++ (singleton self.nixosModule)
      # include home-manager modules
      ++ (singleton home-manager.nixosModules.home-manager)
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
  }

  # the rest of the arguments
  otherArguments
])
