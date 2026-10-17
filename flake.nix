# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  description = "Soxin: a public Nix framework for running a fleet of machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Clan follows the fleet's nixpkgs pin rather than its own unstable one,
    # so a fleet's packages do not move when Soxin is built on Clan.
    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nix-darwin.follows = "nix-darwin";
        sops-nix.follows = "sops-nix";
      };
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      let
        fleetModule = flake-parts-lib.importApply ./modules/fleet {
          soxin = self;
          soxinInputs = inputs;
        };
      in
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        imports = [
          ./checks
        ];

        flake = {
          flakeModules = {
            default = fleetModule;
            fleet = fleetModule;
          };

          lib = import ./lib {
            inherit fleetModule;
            inherit (inputs) flake-parts;
            inherit (inputs.nixpkgs) lib;
          };

          templates.default = {
            path = ./examples/fleet;
            description = "A made-up fleet on Clan: one NixOS and one nix-darwin machine, and one standalone home-manager host";
          };
        };

        perSystem =
          { pkgs, self', ... }:
          {
            packages = {
              guard = pkgs.callPackage ./guard { };
              default = self'.packages.guard;
            };

            apps.guard = {
              type = "app";
              program = "${self'.packages.guard}/bin/soxin-guard";
              meta.description = "Fail when the repository carries private material";
            };

            devShells.default = pkgs.mkShell {
              packages = [
                pkgs.nixfmt
                pkgs.reuse
                self'.packages.guard
              ];
            };

            formatter = pkgs.nixfmt;
          };
      }
    );
}
