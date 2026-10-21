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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The formatter piece (flakeModules.formatter): treefmt for `nix fmt` and
    # git-hooks.nix for the pre-commit hook that runs the same treefmt.
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
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
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      _:
      let
        fleetModules = import ./modules/fleet {
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
          fleetModules.formatter
        ];

        flake = {
          flakeModules = fleetModules // {
            fleet = fleetModules.default;
          };

          lib = import ./lib {
            fleetModule = fleetModules.default;
            inherit (inputs) flake-parts;
            inherit (inputs.nixpkgs) lib;
          };

          # Soxin's module library, all of it (`soxin`) or one module
          # (`<area>-<name>`, e.g. `settings-users`), by kind.
          nixosModules = (import ./modules/library).nixos;
          darwinModules = (import ./modules/library).darwin;
          homeModules = (import ./modules/library).home;

          templates.default = {
            path = ./examples/fleet;
            description = "A made-up fleet on Clan: one NixOS and one nix-darwin machine, and one standalone home-manager host";
          };
        };

        perSystem =
          {
            config,
            pkgs,
            self',
            ...
          }:
          {
            packages = {
              guard = pkgs.callPackage ./guard { };
              parity = pkgs.callPackage ./parity { };
              default = self'.packages.guard;
            };

            apps = {
              guard = {
                type = "app";
                program = "${self'.packages.guard}/bin/soxin-guard";
                meta.description = "Fail when the repository carries private material";
              };

              parity = {
                type = "app";
                program = "${self'.packages.parity}/bin/soxin-parity";
                meta.description = "Compare the derivations of hosts built two ways with nix-diff";
              };
            };

            devShells.default = pkgs.mkShell {
              inputsFrom = [ config.pre-commit.devShell ];
              packages = [
                pkgs.reuse
                self'.packages.guard
                self'.packages.parity
              ];
            };
          };
      }
    );
}
