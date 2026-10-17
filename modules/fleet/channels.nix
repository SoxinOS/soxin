# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Channels: nixpkgs instantiated once per system, each with the shared
# overlays and its own, whose overlays receive every channel of the same
# system. Usable on its own: perSystem `pkgs` becomes the default channel.
{ soxinInputs, ... }:
{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    genAttrs
    literalExpression
    mapAttrs
    mapAttrsToList
    mkDefault
    mkOption
    types
    unique
    ;

  cfg = config.fleet;

  # Every system a host runs on or the flake is evaluated for.
  allSystems = unique (config.systems ++ mapAttrsToList (_: host: host.system) (cfg.hosts or { }));

  instantiate =
    system:
    lib.fix (
      self:
      mapAttrs (
        _: channel:
        import channel.input {
          inherit system;
          config = cfg.channelsConfig // channel.config;
          overlays = cfg.sharedOverlays ++ channel.overlays self;
        }
      ) cfg.channels
    );
in
{
  options.fleet = {
    channels = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            input = mkOption {
              type = types.raw;
              description = "A nixpkgs flake.";
            };

            config = mkOption {
              type = types.attrsOf types.raw;
              default = { };
              description = "nixpkgs configuration of this channel, on top of `fleet.channelsConfig`.";
            };

            overlays = mkOption {
              type = types.functionTo (types.listOf types.raw);
              default = _: [ ];
              example = literalExpression ''
                channels: [
                  (final: prev: { inherit (channels.nixpkgs-unstable) hello; })
                ]
              '';
              description = ''
                A function from every channel of the same system to the
                overlays of this channel, applied after `fleet.sharedOverlays`.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        The nixpkgs channels hosts can use. A host's packages come from its
        channel. The NixOS and nix-darwin modules of every machine come from
        the default channel's nixpkgs, which Clan builds all machines with.
      '';
    };

    defaultChannel = mkOption {
      type = types.str;
      default = "nixpkgs";
      description = "The channel of a host that names none, and the nixpkgs Clan builds machines with.";
    };

    channelsConfig = mkOption {
      type = types.attrsOf types.raw;
      default = { };
      example = {
        allowUnfree = true;
      };
      description = "nixpkgs configuration shared by every channel.";
    };

    sharedOverlays = mkOption {
      type = types.listOf types.raw;
      default = [ ];
      description = "Overlays applied to every channel.";
    };

    packages = mkOption {
      type = types.lazyAttrsOf (types.lazyAttrsOf types.raw);
      readOnly = true;
      description = "Every channel's packages, by system and channel name.";
    };
  };

  config = {
    fleet = {
      channels.nixpkgs.input = mkDefault (inputs.nixpkgs or soxinInputs.nixpkgs);
      packages = genAttrs allSystems instantiate;
    };

    perSystem =
      { system, ... }:
      {
        _module.args.pkgs = mkDefault cfg.packages.${system}.${cfg.defaultChannel};
      };
  };
}
