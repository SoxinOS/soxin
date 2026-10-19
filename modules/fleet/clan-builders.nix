# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Clan's flake-parts module, with per-kind special arguments.
#
# Clan builds every machine with `nixpkgs.lib.nixosSystem` or
# `nix-darwin.lib.darwinSystem`, both taken from the flake's inputs
# (`inputs.nixpkgs`, `inputs.nix-darwin`), and passes one set of special
# arguments to every machine. Soxin imports Clan's module with those two
# inputs replaced by the fleet's nixpkgs (the default channel's) and
# nix-darwin, their system builders wrapped to add `fleet.specialArgs` of the
# machine's kind. Modules can then use them in
# `imports`, and Clan's own evaluations of a machine see the same arguments.
#
# This leans on how Clan's flake module reads its inputs. The
# `clan-builder-wrapper` check fails if Clan stops reading them, so the day it
# does is noticed. Per-host arguments cannot take this route, as the builder
# does not know the machine; machines get them as module arguments.
{ soxinInputs, ... }:
{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.fleet;

  # Marks a machine built through the wrappers; the check reads it.
  marker = "soxinBuilder";

  constructors =
    let
      nixpkgs = cfg.channels.${cfg.defaultChannel}.input;
      nix-darwin = cfg.inputs.nix-darwin;
      withArgs =
        kind: scope: build: args:
        build (
          args
          // {
            specialArgs =
              (args.specialArgs or { }) // cfg.internal.kindArgs kind scope // { ${marker} = kind; };
          }
        );
    in
    {
      nixpkgs = nixpkgs // {
        lib = nixpkgs.lib // {
          nixosSystem = withArgs "nixos" "nixos" nixpkgs.lib.nixosSystem;
        };
      };
      nix-darwin = nix-darwin // {
        lib = nix-darwin.lib // {
          darwinSystem = withArgs "darwin" "darwin" nix-darwin.lib.darwinSystem;
        };
      };
    };

  clanFlakeModule = (inputs.clan-core or soxinInputs.clan-core).flakeModules.default;
in
{
  _file = ./clan-builders.nix;

  imports = [
    (lib.setFunctionArgs (args: clanFlakeModule (args // { inputs = args.inputs // constructors; })) (
      lib.functionArgs clanFlakeModule
    ))
  ];
}
