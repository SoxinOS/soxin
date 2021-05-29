{ deploy-rs
, home-manager
, nixpkgs
, nur
, self
, sops-nix
, unstable
, utils
, ... }:

{
  # inputs of your own soxincfg
  inputs

  # attr attribute set of hosts
  # See https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/e7ae270a23695b50fbb6b72759a7fb1e3340ca86/examples/fully-featured/flake.nix#L101-L112
, hosts

  # Deploy-rs support
  # TODO: implement
, withDeploy ? false

  # Sops-nix support
  # TODO: implement
, withSops ? false

  # The global modules are included in both NixOS and home-manager.
, extraGlobalModules ? [ ]

  # Home-manager specific modules.
, extraHomeManagerModules ? [ ]

  # NixOS specific modules.
, extraNixosModules ? [ ]

  # The global extra arguments are included in both NixOS and home-manager.
, globalSpecialArgs ? { }

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

  # NixOS specific extra arguments.
, nixosSpecialArgs ? { }

  # Evaluates to `packages.<system>.<pname> = <unstable-channel-reference>.<pname>`.
, packagesBuilder ? (_: { })

  # Shared overlays between channels, gets applied to all `channels.<name>.input`
, sharedOverlays ? [ ]

  # Default host settings.
, hostDefaults ? { }
, ...
} @ args:

let
  soxin = self;
  soxincfg = inputs.self;

  inherit (nixpkgs) lib;
  inherit (lib) mapAttrs recursiveUpdate singleton;
  inherit (builtins) removeAttrs;

  otherArguments = removeAttrs args [
    "self"
    "inputs"
    "hosts"
    "withDeploy"
    "withSops"
    "extraGlobalModules"
    "extraHomeManagerModules"
    "extraNixosModules"
    "globalSpecialArgs"
    "hmSpecialArgs"
    "nixosSpecialArgs"
    "packagesBuilder"
    "sharedOverlays"
  ];

  hosts' =
    mapAttrs
      (hostname: host: (recursiveUpdate
        {
          specialArgs = {
            inherit soxin soxincfg home-manager;

            # the mode allows us to tell at what level we are within the modules.
            mode = "NixOS";
          }
          # include the global special arguments.
          // globalSpecialArgs
          # include the NixOS special arguments.
          // nixosSpecialArgs;
        }

        # pass along the hosts minus the deploy key that's specific to soxin.
        (removeAttrs host [ "deploy" ])
      ))
      hosts;

  soxinSystemFlake = {
    # inherit the required fields as-is
    inherit inputs utils;

    # send self as soxincfg
    self = soxincfg;

    # set the hosts
    hosts = hosts';

    # configure the channels.
    channels.nixpkgs.input = nixpkgs;
    channels.unstable.input = unstable;

    # Overlays which are applied to all channels.
    sharedOverlays = [
      # Overlay imported from this flake
      self.overlay
      # Nix User Repository overlay
      nur.overlay
    ]
    # add the sharedOverlays from soxincfg
    ++ sharedOverlays;

    # Evaluates to `packages.<system>.<pname> = <unstable-channel-reference>.<pname>`.
    packagesBuilder = channels:
      recursiveUpdate
        (import ../pkgs channels)
        (packagesBuilder channels);

    # Evaluates to `devShell.<system> = "attributeValue"`
    devShellBuilder = channels: with channels.nixpkgs;
      let
        inherit (lib) optionalAttrs;

        # the base devShell.
        baseShell = mkShell {
          name = "soxincfg";
          buildInputs = [
            nixpkgs-fmt
            pre-commit
          ];
        };

        # overlay the baseShell with things that are only necessary if the
        # user has enabled sops support.
        sopsShell = baseShell.overrideAttrs (oa: {
          sopsPGPKeyDirs = (oa.sopsPGPKeyDirs or [ ]) ++ [
            "./vars/sops-keys/hosts"
            "./vars/sops-keys/users"
          ];

          nativeBuildInputs = (oa.nativeBuildInputs or [ ]) ++ [
            sops-nix.packages.${system}.sops-pgp-hook
          ];

          buildInputs = (oa.buildInputs or [ ]) ++ [
            sops
            sops-nix.packages.${system}.ssh-to-pgp
          ];

          shellHook = (oa.shellHook or "") + ''
            sopsPGPHook
            git config diff.sopsdiffer.textconv "sops -d"
          '';

        });

        # overlay the baseShell with things that are only necessary if the
        # user has enabled deploy-rs support.
        deployShell = sopsShell.overrideAttrs (oa: {
          buildInputs = (oa.buildInputs or [ ]) ++ [
            deploy-rs.packages.${system}.deploy-rs
          ];
        });

        # set the final shell to be returned
        finalShell = deployShell;
      in
      finalShell;

    # configure the modules
    hostDefaults =
      hostDefaults
      // {
        modules =
          # include the modules that are passed in
          (hostDefaults.modules or [ ])
          # include the global modules
          ++ extraGlobalModules
          # include sane flake defaults from utils which sets sane `nix.*` defaults.
          # Please refer to implementation/readme in
          # github:gytis-ivaskevicius/flake-utils-plus for more details.
          ++ (singleton utils.nixosModules.saneFlakeDefaults)
          # include the NixOS modules
          ++ extraNixosModules
          # include Soxin modules
          ++ (singleton self.nixosModule)
          # include home-manager modules
          ++ (singleton home-manager.nixosModules.home-manager)
          # configure home-manager
          ++ (singleton {
            # tell home-manager to use the global (as in NixOS system-level) pkgs and
            # install all  user packages through the users.users.<name>.packages.
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = {
              inherit soxin soxincfg home-manager;

              # the mode allows us to tell at what level we are within the modules.
              mode = "home-manager";
            }
            # include the global special arguments.
            // globalSpecialArgs
            # include the home-manager special arguments.
            // hmSpecialArgs;

            home-manager.sharedModules =
              # include the global modules
              extraGlobalModules
              # include the home-manager modules
              ++ extraHomeManagerModules
              # include Soxin module
              ++ (singleton self.nixosModule);
          });
      };
  };

in
utils.lib.systemFlake (recursiveUpdate soxinSystemFlake otherArguments)
