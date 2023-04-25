{ darwin
, deploy-rs
, home-manager
, flake-utils-plus
, nixpkgs
, nixpkgs-unstable
, nur
, self
, sops-nix
, ...
}:

{
  # inputs of your own soxincfg
  inputs

  # attr attribute set of NixOS hosts
  # See https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/e7ae270a23695b50fbb6b72759a7fb1e3340ca86/examples/fully-featured/flake.nix#L101-L112
  # `builder` and `output` are set automatically
, hosts ? { }  # kept for backwards compatibility, acts as nixosHosts
, nixosHosts ? { }

  # attr attribute set of NixOS hosts
  # See https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/e7ae270a23695b50fbb6b72759a7fb1e3340ca86/examples/fully-featured/flake.nix#L101-L112
  # `builder` and `output` are set automatically
, darwinHosts ? { }

, home-managers ? { }

  # Deploy-rs support
, withDeploy ? false

  # Sops-nix support
, withSops ? false

  # The global modules are included in both NixOS and home-manager.
, extraGlobalModules ? [ ]

  # Darwin specific modules.
, extraDarwinModules ? [ ]

  # Home-manager specific modules.
, extraHomeManagerModules ? [ ]

  # NixOS specific modules.
, extraNixosModules ? [ ]

  # The global extra arguments are included in both NixOS and home-manager.
, globalSpecialArgs ? { }

  # Darwin specific extra arguments.
, darwinSpecialArgs ? { }

  # Home-manager specific extra arguments.
, homeManagerSpecialArgs ? { }

  # NixOS specific extra arguments.
, nixosSpecialArgs ? { }

  # Shared overlays between channels, gets applied to all `channels.<name>.input`
, sharedOverlays ? [ ]

  # See flake-utils-plus for documentation
, outputsBuilder ? (_: { })

  # Default host settings.
, hostDefaults ? { }

  # Generate NIX_PATH from available inputs?
, generateNixPathFromInputs ? true

  # Generate Nix registry from available inputs?
, generateRegistryFromInputs ? true

  # Symlink inputs to /etc/nix/inputs?
, linkInputs ? true
, ...
} @ args:

let
  soxin = self;
  soxincfg = inputs.self;

  inherit (nixpkgs)
    lib
    ;

  inherit (lib)
    asserts
    filterAttrs
    mapAttrs
    optionalAttrs
    optionals
    recursiveUpdate
    singleton
    ;

  inherit (builtins)
    removeAttrs
    ;

  otherArguments = removeAttrs args [
    "self"
    "inputs"
    "nixosHosts"
    "darwinHosts"
    "home-managers"
    "withDeploy"
    "withSops"
    "extraGlobalModules"
    "extraHomeManagerModules"
    "extraNixosModules"
    "globalSpecialArgs"
    "homeManagerSpecialArgs"
    "nixosSpecialArgs"
    "outputsBuilder"
    "sharedOverlays"
  ];

  # generate each host by injecting special arguments and the given host
  # without certain soxin-only attributes.
  nixosHosts' =
    mapAttrs
      (_: host: (recursiveUpdate
        {
          modules = [ ]
            # include modules from the host
            ++ (host.modules or [ ])
            # include NixOS modules
            ++ extraNixosModules
            # include home-manager modules
            ++ (singleton home-manager.nixosModules.home-manager)
          ;

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
        # the other keys are handled above
        (removeAttrs host [ "deploy" "modules" ])
      ))
      (hosts // nixosHosts);

  darwinHosts' =
    mapAttrs
      (_: host: (recursiveUpdate
        {
          modules = [ ]
            # include modules from the host
            ++ (host.modules or [ ])
            # include darwin modules
            ++ extraDarwinModules
            # include home-manager modules
            ++ (singleton home-manager.darwinModules.home-manager)
          ;

          specialArgs = {
            inherit soxin soxincfg home-manager;

            # the mode allows us to tell at what level we are within the modules.
            mode = "darwin";
          }
          # include the global special arguments.
          // globalSpecialArgs
          # include the NixOS special arguments.
          // darwinSpecialArgs;

          output = "darwinConfigurations";
          builder = darwin.lib.darwinSystem;
        }

        # pass along the hosts minus the deploy key that's specific to soxin.
        # the other keys are handled above
        (removeAttrs host [ "deploy" "modules" ])
      ))
      darwinHosts;

  # Generate the deployment nodes.
  deploy.nodes =
    let
      # filter out hosts without a deploy attribute.
      deploy-hosts = filterAttrs (n: v: (v.deploy or { }) != { }) hosts;
    in
    mapAttrs (hostname: host: host.deploy) deploy-hosts;

  soxinSystemFlake = {
    # inherit the required fields as-is
    inherit inputs flake-utils-plus;

    # send self as soxincfg
    self = soxincfg;

    # set the hosts
    hosts = darwinHosts' // nixosHosts';

    # configure the channels.
    channels.nixpkgs.input = nixpkgs;
    channels.nixpkgs-unstable.input = nixpkgs-unstable;

    # Overlays which are applied to all channels.
    sharedOverlays = [
      # Overlay imported from this flake
      self.overlay
      # Nix User Repository overlay
      nur.overlay
    ]
    # pass along the sharedModules
    ++ sharedOverlays
    # pass along sops-nix overlay.
    ++ optionals withSops (singleton sops-nix.overlay);

    # TODO: Add support for modifying the outputsBuilder.
    outputsBuilder = channels:
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
              sops-pgp-hook
              ssh-to-pgp
              ;

            userShell = userOutputs.devShell or (mkShell { name = "devShell"; });

            # the base devShell.
            baseShell = userShell.overrideAttrs (oa: {
              name = "soxincfg";
              buildInputs = (oa.buildInputs or [ ]) ++ [ nixpkgs-fmt pre-commit ];
            });

            # overlay the baseShell with things that are only necessary if the
            # user has enabled sops support.
            sopsShell = baseShell.overrideAttrs (oa: optionalAttrs withSops {
              buildInputs = (oa.buildInputs or [ ]) ++ [ sops ssh-to-pgp ];
              nativeBuildInputs = (oa.nativeBuildInputs or [ ]) ++ [ sops-pgp-hook ];
              sopsPGPKeyDirs = (oa.sopsPGPKeyDirs or [ ]) ++ [ "./vars/sops-keys/hosts" "./vars/sops-keys/users" ];

              shellHook = (oa.shellHook or "") + ''
                sopsPGPHook
                git config diff.sopsdiffer.textconv "sops -d"
              '';
            });

            # overlay the baseShell with things that are only necessary if the
            # user has enabled deploy-rs support.
            deployShell = sopsShell.overrideAttrs (oa: optionalAttrs withDeploy {
              buildInputs = (oa.buildInputs or [ ]) ++ [ deploy-rs.packages.${nixpkgs.system}.deploy-rs ];
            });

            homeManagerShell = deployShell.overrideAttrs (oa: optionalAttrs (home-managers != { }) {
              buildInputs = (oa.buildInputs or [ ]) ++ [ home-manager.packages.${nixpkgs.system}.home-manager ];
            });

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
    hostDefaults =
      hostDefaults
        // {
        modules =
          # include the modules that are passed in
          (hostDefaults.modules or [ ])
            # include sops
            ++ (optionals withSops (singleton sops-nix.nixosModules.sops))
            # include the global modules
            ++ extraGlobalModules
            # include Soxin modules
            ++ (singleton soxin.nixosModule)
            # configure fup to expose NIX_PATH and Nix registry from inputs.
            ++ (singleton { nix = { inherit generateNixPathFromInputs generateRegistryFromInputs linkInputs; }; })
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
            // homeManagerSpecialArgs;

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

flake-utils-plus.lib.mkFlake (recursiveUpdate soxinSystemFlake otherArguments)

  # TODO: Let flake-utils-plus.lib.mkFlake handle the home-managers by using the host's builder function
  // {
  homeConfigurations = (mapAttrs
    (hostname: host: soxin.lib.homeManagerConfiguration (host // {
      inherit inputs;
      hmModules =
        # include the global modules
        extraGlobalModules
        # include the home-manager modules
        ++ extraHomeManagerModules;
    }))
    home-managers);
}
