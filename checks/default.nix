# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's own checks: the private-material guard on this repository, its
# fixture test, formatting, REUSE compliance and the example fleet.
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

        formatting = pkgs.runCommandLocal "soxin-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          cd ${self}
          find . -name '*.nix' -print0 | xargs -0 nixfmt --check
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
