{
  description = "Soxin template flake";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/release-21.05;
    unstable.url = github:nixos/nixpkgs/nixos-unstable;
    nur.url = github:nix-community/NUR;
    utils.url = path:../../../gytis-ivaskevicius/flake-utils-plus;

    home-manager = {
      url = github:nix-community/home-manager/release-21.05;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    soxin = {
      url = "github:SoxinOS/soxin";
      inputs = {
        nixpkgs.follows = "nixos";
        home-manager.follows = "home-manager";
        utils.follows = "utils";
      };
    };
  };

  outputs = inputs@{ self, nixpkgs, unstable, nur, utils, home-manager, soxin }:
    soxin.lib.systemFlake {
      deploy-rs.eanble = true;

      sops.enable = true;

      # Supported systems, used for packages, apps, devShell and multiple other definitions. Defaults to `flake-utils.lib.defaultSystems`
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Default host settings.
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

      hosts = import ./hosts { inherit inputs; };
    };
}
