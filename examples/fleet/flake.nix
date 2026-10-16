# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  description = "An example Soxin fleet, with made-up hosts and users";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    soxin = {
      url = "github:SoxinOS/soxin/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.soxin.lib.mkFleet ({ inherit inputs; } // import ./fleet.nix inputs);
}
