{ deploy-rs
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

  # attr attribute set of hosts
  # See https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/e7ae270a23695b50fbb6b72759a7fb1e3340ca86/examples/fully-featured/flake.nix#L101-L112
, hosts ? { }

, home-managers ? { }

  # Deploy-rs support
, withDeploy ? false

  # Sops-nix support
, withSops ? false

  # The global modules are included in both NixOS and home-manager.
, extraGlobalModules ? [ ]

  # Home-manager specific modules.
, extraHomeManagerModules ? [ ]

  # NixOS specific modules.
, extraNixosModules ? [ ]

  # nix-darwin specific modules.
, extraNixDarwinModules ? [ ]

  # The global extra arguments are included in both NixOS and home-manager.
, globalSpecialArgs ? { }

  # Home-manager specific extra arguments.
, hmSpecialArgs ? { }

  # NixOS specific extra arguments.
, nixosSpecialArgs ? { }

  # nix-darwin specific extra arguments.
, nixDarwinSpecialArgs ? { }

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
  inherit (lib) asserts filterAttrs mapAttrs optionalAttrs optionals recursiveUpdate singleton;
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
    "packagesBuilder"
    "sharedOverlays"
  ];

  # generate each host by injecting special arguments and the given host
  # without certain soxin-only attributes.
  hosts' =
    let
      # TODO: make this more generic
      # hostOS = host: builtins.head (builtins.tail (builtins.split ".*-(linux|darwin)" host.system));
      # isDarwin = system: (lib.systems.parse.mkSystemFromString system)
      isDarwin = host: host.system == "x86_64-darwin";
      isLinux = host: host.system == "x86_64-linux" || host.system == "aarch64-linux";

      darwinHosts =
        let
          darwinOnlyHosts = filterAttrs (n: host: isDarwin host) hosts;
        in
        mapAttrs
          (hostname: host: (recursiveUpdate
            {
              specialArgs = {
                inherit soxin soxincfg home-manager;

                # the mode allows us to tell at what level we are within the modules.
                mode = "nix-darwin";
              }
              # include the global special arguments.
              // globalSpecialArgs
              # include the NixDarwin special arguments.
              // nixDarwinSpecialArgs;
            }

            # pass along the hosts minus the deploy key that's specific to soxin.
            (removeAttrs host [ "deploy" ])
          ))
          darwinOnlyHosts;

      nixosHosts =
        let
          nixosOnlyHosts = filterAttrs (n: host: isLinux host) hosts;
        in
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
          nixosOnlyHosts;
    in
    darwinHosts // nixosHosts;

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
    hosts = hosts';

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

    # Evaluates to `packages.<system>.<pname> = <unstable-channel-reference>.<pname>`.
    packagesBuilder = channels:
      let
        inherit (channels) nixpkgs;
      in
      recursiveUpdate
        # these packages construct themselves if and only if the system is supported.
        (import ../pkgs nixpkgs)
        # pass along the packagesBuilder
        (packagesBuilder channels);

    # Evaluates to `devShell.<system> = "attributeValue"`
    devShellBuilder = channels: with channels.nixpkgs;
      let
        # the base devShell.
        baseShell = mkShell {
          name = "soxincfg";
          buildInputs = [
            nixpkgs-fmt
            pre-commit

            # Source: https://github.com/chvp/nixos-config/blob/51b76511816d03e94b87cdc8096ce437ec43756b/flake.nix#L46
            # TODO: make this more useful by generalizing it.
            # (pkgs.writeShellScriptBin "fetchpatch" "curl -L https://github.com/NixOS/nixpkgs/pull/$1.patch -o patches/$1.patch")
          ];
        };

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
          buildInputs = (oa.buildInputs or [ ]) ++ [ deploy-rs.packages.${system}.deploy-rs ];
        });

        homeManagerShell = deployShell.overrideAttrs (oa: optionalAttrs (home-managers != { }) {
          buildInputs = (oa.buildInputs or [ ]) ++ [ home-manager.packages.${system}.home-manager ];
        });

        # set the final shell to be returned
        finalShell = homeManagerShell;
      in
      finalShell;

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
            # include sane flake defaults from flake-utils-plus which sets sane `nix.*` defaults.
            # Please refer to implementation/readme in
            # github:gytis-ivaskevicius/flake-utils-plus for more details.
            ++ (singleton flake-utils-plus.nixosModules.saneFlakeDefaults)
            # include the NixOS modules
            ++ extraNixosModules
            # include Soxin modules
            ++ (singleton soxin.nixosModule)
            # include home-manager modules
            ++ (singleton home-manager.nixosModules.home-manager)
            # configure home-manager
            ++ (singleton {
            # tell home-manager to use the global (as in NixOS system-level) pkgs and
            # install all  user packages through the users.users.<name>.packages.
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # TODO: Must wire up extraNixDarwinModules

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

assert asserts.assertMsg (hosts != { } || home-managers != { }) "At least hosts or home-managers must be set";

flake-utils-plus.lib.systemFlake (recursiveUpdate soxinSystemFlake otherArguments)

  # TODO: Let flake-utils-plus.lib.systemFlake handle the home-managers by using the host's builder function
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
