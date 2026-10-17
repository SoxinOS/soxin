# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# The fleet's settings, kept apart from flake.nix so Soxin's own checks can
# evaluate this example with Soxin's inputs.
inputs: {
  root = ./.;

  channels = {
    nixpkgs-unstable.input = inputs.nixpkgs-unstable;

    # Take a package from unstable while the rest of the system stays on the
    # release.
    nixpkgs.overlays = channels: [
      (_final: _prev: { inherit (channels.nixpkgs-unstable) hello; })
    ];
  };

  defaultProfiles = [ "base" ];

  # Adds the sops-nix module everywhere; the example declares no secrets.
  sops.enable = true;

  # Extra arguments for every module, e.g. hardware or WSL modules:
  #   specialArgs.nixos = { inherit (inputs) nixos-hardware nixos-wsl; };
  specialArgs.global.fleetName = "example";

  # Pin the machines' Nix registry and NIX_PATH to this flake's inputs.
  pinInputs = {
    registry = true;
    nixPath = true;
  };

  # Expose modules and profiles as nixosModules, darwinModules, homeModules.
  exportModules = true;
}
