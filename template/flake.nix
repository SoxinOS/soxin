{
  description = "Soxin template flake";

  inputs = {
    darwin.url = "github:lnl7/nix-darwin/master";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus/v1.1.0";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.05";
    nur.url = "github:nix-community/NUR";

    darwin.inputs.nixpkgs.follows = "nixpkgs";

    soxin = {
      url = "github:SoxinOS/soxin";
      inputs = {
        darwin.follows = "darwin";
        deploy-rs.follows = "deploy-rs";
        flake-utils-plus.follows = "flake-utils-plus";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nixpkgs.follows = "nixpkgs";
        nur.follows = "nur";
      };
    };
  };

  outputs = inputs@{ flake-utils-plus, nixos-hardware, nixpkgs, self, soxin, ... }:
    let
      # Enable deploy-rs support
      withDeploy = true;

      # Enable sops support
      withSops = true;

      inherit (nixpkgs) lib;
      inherit (lib) optionalAttrs recursiveUpdate singleton;
      inherit (flake-utils-plus.lib) flattenTree;

      # Channel definitions. `channels.<name>.{input,overlaysBuilder,config,patches}`
      channels = {
        nixpkgs = {
          # Channel specific overlays
          overlaysBuilder = channels: [
            (final: prev: { })
          ];

          # Channel specific configuration. Overwrites `channelsConfig` argument
          config = { };

          # Yep, you see it first folks - you can patch nixpkgs!
          patches = [ ];
        };
      };

      # Default configuration values for `channels.<name>.config = {...}`
      channelsConfig = {
        # allowBroken = true;
        allowUnfree = true;
        # allowUnsupportedSystem = true;
      };

      nixosModules = (import ./modules) // {
        soxincfg = import ./modules/soxincfg.nix;
        profiles = import ./profiles;
      };

      nixosModule = nixosModules.soxincfg;

    in
    soxin.lib.systemFlake {
      inherit channels channelsConfig inputs withDeploy withSops nixosModules nixosModule;

      # add Soxin's main module to all builders
      extraGlobalModules = [ nixosModule nixosModules.profiles.core ];

      # Supported systems, used for packages, apps, devShell and multiple other definitions. Defaults to `flake-utils.lib.defaultSystems`
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # pull in all hosts
      hosts = import ./hosts inputs;

      # create all home-managers
      home-managers = import ./home-managers inputs;

      # Evaluates to `packages.<system>.<pname> = <unstable-channel-reference>.<pname>`.
      packagesBuilder = channels: flattenTree (import ./pkgs channels);

      # declare the vars that are used only by sops
      vars = optionalAttrs withSops (import ./vars inputs);

      # include all overlays
      overlay = import ./overlays;

      # set the nixos specialArgs
      nixosSpecialArgs = { inherit nixos-hardware; };
    };
}
