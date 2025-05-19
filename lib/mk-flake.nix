{
  darwin,
  deploy-rs,
  home-manager,
  flake-utils-plus,
  nur,
  self,
  sops-nix,
  ...
}:

{
  # inputs of your own soxincfg
  inputs,

  # channels configuration
  channels ? { },

  # attr attribute set of hosts
  # See https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/e7ae270a23695b50fbb6b72759a7fb1e3340ca86/examples/fully-featured/flake.nix#L101-L112
  hosts ? { },

  home-managers ? { },

  # Deploy-rs support
  withDeploy ? false,

  # Sops-nix support
  withSops ? false,

  # The global modules are included in both NixOS and home-manager.
  extraGlobalModules ? [ ],

  # Home-manager specific modules.
  extraHomeManagerModules ? [ ],

  # NixOS specific modules.
  extraNixosModules ? [ ],

  # nix-darwin specific modules.
  extraNixDarwinModules ? [ ],

  # The global extra arguments are included everywhere.
  globalSpecialArgs ? { },

  # Home-manager specific extra arguments.
  hmSpecialArgs ? { },

  # NixOS specific extra arguments.
  nixosSpecialArgs ? { },

  # nix-darwin specific extra arguments.
  nixDarwinSpecialArgs ? { },

  # Shared overlays between channels, gets applied to all `channels.<name>.input`
  sharedOverlays ? [ ],

  # See flake-utils-plus for documentation
  outputsBuilder ? (_: { }),

  # Default host settings.
  hostDefaults ? { },

  # Generate NIX_PATH from available inputs?
  generateNixPathFromInputs ? true,

  # Generate Nix registry from available inputs?
  generateRegistryFromInputs ? true,

  # Symlink inputs to /etc/nix/inputs?
  linkInputs ? true,
  ...
}@args:

let
  assertMsg = pred: msg: pred || builtins.throw msg;
in
assert assertMsg (
  channels ? "nixpkgs" && channels.nixpkgs ? "input"
) "You must pass in channels.nixpkgs.input";

let
  soxin = self;
  soxincfg = inputs.self;

  inherit (channels.nixpkgs.input) lib;

  inherit (lib)
    asserts
    filterAttrs
    mapAttrs
    optionalAttrs
    optionals
    recursiveUpdate
    singleton
    ;

  inherit (builtins) removeAttrs;

  otherArguments = removeAttrs args [
    "self"
    "inputs"
    "hosts"
    "home-managers"
    "withDeploy"
    "withSops"
    "extraGlobalModules"
    "extraHomeManagerModules"
    "extraNixosModules"
    "extraNixDarwinModules"
    "globalSpecialArgs"
    "hmSpecialArgs"
    "nixosSpecialArgs"
    "nixDarwinSpecialArgs"
    "outputsBuilder"
    "sharedOverlays"
  ];

  # Overlays which are applied to all channels.
  sharedOverlays' =
    [
      # Overlay imported from this flake
      self.overlays.default
      # Nix User Repository overlay
      nur.overlays.default
    ]
    # pass along the sharedModules
    ++ sharedOverlays
    # pass along sops-nix overlays.
    ++ optionals withSops (singleton sops-nix.overlays.default);

  # generate each host by injecting special arguments and the given host
  # without certain soxin-only attributes.
  hosts' =
    let
      darwinHosts =
        let
          darwinOnlyHosts = filterAttrs (n: host: host.mode == "nix-darwin") hosts;

          # Build host with darwinSystem.
          builder = args: darwin.lib.darwinSystem args;

          # Setup the output
          output = "darwinConfigurations";
        in
        mapAttrs (
          _: host:
          # setup the default attributes, users can override it by passing them through their host definition.
          {
            inherit builder output;
          }
          // (recursiveUpdate
            # pass along the hosts minus few keys that are implementation detail to soxin.
            (removeAttrs host [
              "deploy"
              "mode"
              "modules"
            ])

            {
              modules =
                [ ]
                # include modules for the host
                ++ (host.modules or [ ])
                # include the NixOS modules
                ++ extraNixDarwinModules
                # include home-manager modules
                ++ (singleton home-manager.darwinModules.home-manager)
                # configure home-manager with host-specific settings
                ++ (singleton { home-manager.extraSpecialArgs = host.specialArgs; });

              specialArgs =
                {
                  inherit
                    home-manager
                    inputs
                    soxin
                    soxincfg
                    ;

                  inherit (host) mode;
                }
                # include the specialArgs that were passed in.
                // (host.specialArgs or { })
                # include the global special arguments.
                // globalSpecialArgs
                # include the NixDarwin special arguments.
                // nixDarwinSpecialArgs;
            }
          )
        ) darwinOnlyHosts;

      nixosHosts =
        let
          nixosOnlyHosts = filterAttrs (n: host: host.mode == "NixOS") hosts;
        in
        mapAttrs (
          _: host:
          (recursiveUpdate
            # pass along the hosts minus few keys that are implementation detail to soxin.
            (removeAttrs host [
              "deploy"
              "mode"
            ])

            {
              modules =
                [ ]
                # include modules for the host
                ++ (host.modules or [ ])
                # include the NixOS modules
                ++ extraNixosModules
                # include sops
                ++ (optionals withSops (singleton sops-nix.nixosModules.sops))
                # include home-manager modules
                ++ (singleton home-manager.nixosModules.home-manager)
                # configure home-manager with host-specific settings
                ++ (singleton { home-manager.extraSpecialArgs = host.specialArgs; });

              specialArgs =
                {
                  inherit
                    home-manager
                    inputs
                    soxin
                    soxincfg
                    ;

                  inherit (host) mode;
                }
                # include the specialArgs that were passed in.
                // (host.specialArgs or { })
                # include the global special arguments.
                // globalSpecialArgs
                # include the NixOS special arguments.
                // nixosSpecialArgs;
            }
          )
        ) nixosOnlyHosts;

    in
    # TODO: add support for home-manager modes
    darwinHosts // nixosHosts;

  # Generate the deployment nodes.
  deploy.nodes =
    let
      # filter out hosts without a deploy attribute.
      deploy-hosts = filterAttrs (n: v: (v.deploy or { }) != { }) hosts;
    in
    mapAttrs (_: host: host.deploy) deploy-hosts;

  soxinSystemFlake =
    {
      # inherit the required fields as-is
      inherit inputs flake-utils-plus;

      # Overlays which are applied to all channels.
      sharedOverlays = sharedOverlays';

      # send self as soxincfg
      self = soxincfg;

      # set the hosts
      hosts = hosts';

      # TODO: Add support for modifying the outputsBuilder.
      outputsBuilder =
        channels:
        let
          userOutputs = outputsBuilder channels;

          # Evaluates to `packages.<system>.coreutils = <unstable-nixpkgs-reference>.package-from-overlays`.
          soxinPackages =
            let
              inherit (channels) nixpkgs;
            in
            # these packages construct themselves if and only if the system is supported.
            (import ../pkgs nixpkgs);

          # Evaluates to `devShell.<system> = <nixpkgs-channel-reference>.mkShell { name = "devShell"; };`.
          devShell =
            let
              inherit (channels) nixpkgs;

              inherit (nixpkgs)
                mkShell
                nixpkgs-fmt
                pre-commit
                sops
                sops-import-keys-hook
                ssh-to-pgp
                ;

              userShell = userOutputs.devShell or (mkShell { name = "devShell"; });

              # the base devShell.
              baseShell = userShell.overrideAttrs (oa: {
                name = "soxincfg";
                buildInputs = (oa.buildInputs or [ ]) ++ [
                  nixpkgs-fmt
                  pre-commit
                ];
              });

              # overlay the baseShell with things that are only necessary if the
              # user has enabled sops support.
              sopsShell = baseShell.overrideAttrs (
                oa:
                optionalAttrs withSops {
                  buildInputs = (oa.buildInputs or [ ]) ++ [
                    sops
                    ssh-to-pgp
                  ];
                  nativeBuildInputs = (oa.nativeBuildInputs or [ ]) ++ [ sops-import-keys-hook ];
                  sopsPGPKeyDirs = (oa.sopsPGPKeyDirs or [ ]) ++ [
                    "./vars/sops-keys/hosts"
                    "./vars/sops-keys/users"
                  ];

                  shellHook =
                    (oa.shellHook or "")
                    + ''
                      sopsImportKeysHook
                      git config diff.sopsdiffer.textconv "sops -d"
                    '';
                }
              );

              # overlay the baseShell with things that are only necessary if the
              # user has enabled deploy-rs support.
              deployShell = sopsShell.overrideAttrs (
                oa:
                optionalAttrs withDeploy {
                  buildInputs = (oa.buildInputs or [ ]) ++ [ deploy-rs.packages.${nixpkgs.system}.deploy-rs ];
                }
              );

              homeManagerShell = deployShell.overrideAttrs (
                oa:
                optionalAttrs (home-managers != { }) {
                  buildInputs = (oa.buildInputs or [ ]) ++ [ home-manager.packages.${nixpkgs.system}.home-manager ];
                }
              );

              # set the final shell to be returned
              finalShell = homeManagerShell;
            in
            finalShell;

          outputs = recursiveUpdate userOutputs {
            inherit devShell;
            packages = recursiveUpdate soxinPackages (userOutputs.packages or { });
          };
        in
        outputs;

      # configure the modules
      hostDefaults = hostDefaults // {
        modules =
          # include the modules that are passed in
          (hostDefaults.modules or [ ])
          # include the global modules
          ++ extraGlobalModules
          # include Soxin modules
          ++ (singleton soxin.nixosModule)
          # configure fup to expose NIX_PATH and Nix registry from inputs.
          ++ (singleton {
            nix = {
              inherit generateNixPathFromInputs generateRegistryFromInputs linkInputs;
            };
          })
          # configure home-manager
          ++ (singleton {
            # tell home-manager to use the global (as in NixOS/Nix-Darwin
            # system-level) pkgs and install all user packages through the
            # users.users.<name>.packages.
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs =
              {
                inherit
                  inputs
                  soxin
                  soxincfg
                  home-manager
                  ;

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
              ++ (singleton soxin.nixosModule);
          });
      };
    }
    // (optionalAttrs withDeploy {
      inherit deploy;

      # add the deploy-rs checks
      checks = mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;
    });

in

assert asserts.assertMsg (
  hosts != { } || home-managers != { }
) "At least hosts or home-managers must be set";

flake-utils-plus.lib.mkFlake (recursiveUpdate soxinSystemFlake otherArguments)

# TODO: Let flake-utils-plus.lib.mkFlake handle the home-managers by using the host's builder function
// {
  homeConfigurations = (
    mapAttrs (
      _: host:
      soxin.lib.homeManagerConfiguration (
        host
        // {
          inherit inputs;

          specialArgs =
            { }
            # include the specialArgs that were passed in.
            // (host.specialArgs or { })
            # include the global special arguments.
            // globalSpecialArgs
            # include the home-manager special arguments.
            // hmSpecialArgs;

          modules =
            host.modules
            # include the global modules
            ++ extraGlobalModules
            # include the home-manager modules
            ++ extraHomeManagerModules;

          overlays = sharedOverlays';
        }
      )
    ) home-managers
  );
}
