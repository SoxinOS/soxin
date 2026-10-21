# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's own checks: the private-material guard on this repository, its
# fixture test, the parity app's tests, REUSE compliance and the example
# fleet. Formatting is checked by the formatter piece (`treefmt`,
# `pre-commit`).
{ inputs, self, ... }:

let
  # The example fleet, evaluated with Soxin's inputs in place of the ones its
  # flake.nix pins. Its unstable channel is Soxin's nixpkgs, so checking Soxin
  # does not fetch a second nixpkgs.
  exampleInputs = inputs // {
    self = {
      outPath = ../examples/fleet;
    };
    soxin = self;
    nixpkgs-unstable = inputs.nixpkgs;
  };

  example = self.lib.mkFleet (
    { inputs = exampleInputs; } // import ../examples/fleet/fleet.nix exampleInputs
  );
in
{
  perSystem =
    {
      lib,
      pkgs,
      self',
      system,
      ...
    }:
    {
      checks = {
        guard = pkgs.runCommandLocal "soxin-guard-self" { } ''
          ${lib.getExe self'.packages.guard} ${self}
          touch $out
        '';

        guard-fixtures = pkgs.callPackage ../guard/fixtures.nix { guard = self'.packages.guard; };

        # Soxin passes `fleet.specialArgs` per kind to Clan's machines by
        # wrapping the builders Clan takes from `inputs.nixpkgs` and
        # `inputs.nix-darwin` (modules/fleet/clan-builders.nix). Fails when a
        # machine was built without the wrappers, i.e. when Clan stops
        # reading those inputs.
        clan-builder-wrapper =
          let
            builtBy = configuration: configuration._module.specialArgs.soxinBuilder or null;
            server = builtBy example.nixosConfigurations.example-server;
            laptop = builtBy example.darwinConfigurations.example-laptop;
          in
          assert lib.assertMsg (server == "nixos")
            "Clan built example-server without Soxin's nixosSystem wrapper; it no longer reads inputs.nixpkgs";
          assert lib.assertMsg (laptop == "darwin")
            "Clan built example-laptop without Soxin's darwinSystem wrapper; it no longer reads inputs.nix-darwin";
          pkgs.runCommandLocal "soxin-clan-builder-wrapper" { } "touch $out";

        parity = pkgs.runCommandLocal "soxin-parity-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          python3 ${../parity/test-parity.py} ${../parity/soxin-parity.py}
          touch $out
        '';

        reuse = pkgs.runCommandLocal "soxin-reuse" { nativeBuildInputs = [ pkgs.reuse ]; } ''
          reuse --root ${self} lint
          touch $out
        '';
      }
      // lib.mapAttrs' (name: lib.nameValuePair "example-${name}") example.checks.${system};
    };
}
