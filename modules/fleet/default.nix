# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's flake-parts modules, each importable on its own:
#
# - channels: nixpkgs channels whose overlays see every channel;
# - profiles: profiles and the fleet's modules by kind, optionally exported;
# - hosts: the hosts, the frameworks, sops-nix and the module arguments;
# - homes: standalone home-manager hosts;
# - machines: NixOS and nix-darwin machines on Clan (with clan-builders and
#   pin-inputs);
# - checks: an evaluation check per host;
# - library: Soxin's module library on every host;
# - default: all of them.
#
# Each carries a `key`, so importing several of them, or one twice, declares
# its options once.
args:
let
  piece = name: file: {
    key = "soxin#${name}";
    _file = file;
    imports = [ (import file (args // { inherit modules; })) ];
  };

  modules = {
    channels = piece "channels" ./channels.nix;
    profiles = piece "profiles" ./profiles.nix;
    hosts = piece "hosts" ./hosts.nix;
    homes = piece "homes" ./homes.nix;
    clan-builders = piece "clan-builders" ./clan-builders.nix;
    pin-inputs = piece "pin-inputs" ./pin-inputs.nix;
    machines = piece "machines" ./machines.nix;
    checks = piece "checks" ./checks.nix;
    library = piece "library" ./library.nix;
    default = {
      key = "soxin#default";
      imports = [
        modules.library
        modules.homes
        modules.machines
        modules.checks
      ];
    };
  };
in
modules
