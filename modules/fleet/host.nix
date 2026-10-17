# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# The options of one host, `fleet.hosts.<name>`. A `machines/<name>/host.nix` or
# `homes/<name>/host.nix` is a module of this type, so it may be a plain
# attribute set or a function of
# `{ inputs, name, config, lib, ... }`.
{ defaultChannel }:
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    kind = mkOption {
      type = types.enum [
        "nixos"
        "darwin"
        "home-manager"
      ];
      description = ''
        What the host is: a NixOS system, a nix-darwin system or a standalone
        home-manager configuration.
      '';
    };

    system = mkOption {
      type = types.str;
      example = "x86_64-linux";
      description = "The platform the host runs on.";
    };

    channel = mkOption {
      type = types.str;
      default = defaultChannel;
      defaultText = lib.literalExpression "config.fleet.defaultChannel";
      description = "The name of the channel, from `fleet.channels`, whose packages and modules the host uses.";
    };

    profiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "workstation" ];
      description = ''
        Names of the profiles, from `fleet.profiles`, the host takes on top of
        `fleet.defaultProfiles`.
      '';
    };

    modules = mkOption {
      type = types.listOf types.raw;
      default = [ ];
      description = ''
        Modules of the host itself: NixOS modules for a `nixos` host,
        nix-darwin modules for a `darwin` host and home-manager modules for a
        `home-manager` host.
      '';
    };

    specialArgs = mkOption {
      type = types.attrsOf types.raw;
      default = { };
      description = "Extra arguments passed to the host's modules, on top of `fleet.specialArgs`.";
    };
  };
}
