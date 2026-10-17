# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Opt-in pinning of the Nix registry and NIX_PATH of NixOS and nix-darwin
# machines to the fleet's flake inputs, as Soxin v1 did by default.
_:
{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mapAttrs'
    mkIf
    mkMerge
    mkOption
    nameValuePair
    types
    ;

  cfg = config.fleet.pinInputs;

  flakes = filterAttrs (_: input: input ? outputs) inputs;
in
{
  options.fleet.pinInputs = {
    registry = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to put every flake input of the fleet into the machines' Nix registry, under its input name.";
    };

    nixPath = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to link every input of the fleet to `/etc/nix/inputs/<name>`
        on the machines and point NIX_PATH at that directory, so
        `<nixpkgs>` is the fleet's nixpkgs.
      '';
    };

    module = mkOption {
      # A plain module rather than a deferredModule, which would nest it
      # deeper in the module tree and move its list definitions ahead of the
      # fleet's.
      type = types.raw;
      readOnly = true;
      internal = true;
      description = "The NixOS and nix-darwin module that pins the inputs.";
    };
  };

  config.fleet.pinInputs.module = {
    _file = ./pin-inputs.nix;
    config = mkMerge [
      (mkIf cfg.registry {
        nix.registry = mapAttrs (_: flake: { inherit flake; }) flakes;
      })
      (mkIf cfg.nixPath {
        environment.etc = mapAttrs' (
          name: input: nameValuePair "nix/inputs/${name}" { source = input.outPath; }
        ) inputs;
        nix.nixPath = [ "/etc/nix/inputs" ];
      })
    ];
  };
}
