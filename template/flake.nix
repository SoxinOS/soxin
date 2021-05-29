{
  description = "Soxin template flake";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nixpkgs.url = github:NixOS/nixpkgs/release-21.05;
    sops-nix.url = "github:Mic92/sops-nix";
    unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    utils.url = github:gytis-ivaskevicius/flake-utils-plus/v1.1.0;

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    soxin = {
      url = path:../.;
      inputs = {
        deploy-rs.follows = "deploy-rs";
        nixpkgs.follows = "nixpkgs";
        sops-nix.follows = "sops-nix";
        unstable.follows = "unstable";
        utils.follows = "utils";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = inputs@{ self, soxin, ... }:
    soxin.lib.systemFlake {
      inherit inputs;

      # Enable deploy-rs support
      withDeploy = true;

      # Enable sops support
      withSops = true;

      # Supported systems, used for packages, apps, devShell and multiple other definitions. Defaults to `flake-utils.lib.defaultSystems`
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Default host settings.
      # Full documentation: https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/master/examples/fully-featured/flake.nix#L33
      hostDefaults = {
        # Default architecture to be used for `hosts` defaults to "x86_64-linux"
        system = "x86_64-linux";
        # Default channel to be used for `hosts` defaults to "nixpkgs"
        channelName = "unstable";
        # Extra arguments to be passed to modules. Merged with host's extraArgs
        extraArgs = { };
        # Default modules to be passed to all hosts.
        modules = [ ];
      };

      hosts = import ./hosts inputs;
    };
}
