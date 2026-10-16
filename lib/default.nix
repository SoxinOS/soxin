# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  lib,
  flake-parts,
  fleetModule,
}:

{
  /**
    Build the outputs of a fleet flake.

    A thin wrapper around `flake-parts.lib.mkFlake` with the fleet module
    imported. Every attribute other than `inputs`, `systems` and `imports` is
    passed to the `fleet` options, so

      mkFleet { inherit inputs; root = ./.; sops.enable = true; }

    is the same as a flake-parts flake that imports `soxin.flakeModules.default`
    and sets `fleet = { root = ./.; sops.enable = true; }`.

    `imports` takes extra flake-parts modules, for anything the fleet options do
    not cover (packages, dev shells, more checks).
  */
  mkFleet =
    {
      inputs,
      systems ? [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ],
      imports ? [ ],
      ...
    }@args:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ fleetModule ] ++ imports;
      inherit systems;
      fleet = lib.removeAttrs args [
        "inputs"
        "systems"
        "imports"
      ];
    };
}
