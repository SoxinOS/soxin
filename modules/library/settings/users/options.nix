# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# `soxin.settings.users`: the fleet's users, declared once and created on
# NixOS and nix-darwin, with groups other modules contribute to.
{ config, lib, ... }:

let
  inherit (lib)
    literalExpression
    mapAttrs
    mkOption
    recursiveUpdate
    types
    ;

  cfg = config.soxin.settings.users;
in
{
  options.soxin.settings.users = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to create `users` on the system.";
    };

    userName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "alice";
      description = "The main user, whose computed attributes `user` gives.";
    };

    user = mkOption {
      type = types.attrs;
      default = config.users.users.${cfg.userName};
      defaultText = literalExpression "config.users.users.\${userName}";
      readOnly = true;
      description = "The computed attributes of the main user.";
    };

    users = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          alice = {
            isAdmin = true;
            sshKeys = [ "ssh-ed25519 AAAA... alice@example.com" ];
          };
        }
      '';
      description = ''
        The users to create, by name. Each takes `isAdmin`, `isNixTrustedUser`
        and `sshKeys` besides the attributes of `users.users.<name>`, on top
        of `userDefaults`.
      '';
      # Defaults first, then the name, then the user's own attributes, which
      # win over both.
      apply = mapAttrs (
        name: user: recursiveUpdate (cfg.internal.baseDefaults name // cfg.userDefaults) user
      );
    };

    userDefaults = mkOption {
      type = types.attrs;
      default = { };
      example = {
        hashedPassword = "!";
      };
      description = "Attributes every user gets unless it sets them itself.";
    };

    groups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Groups every user is added to; modules add theirs (e.g. `adbusers`).";
    };

    defaultGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "users"
        "video"
      ];
      description = "Groups every user is added to before `groups` (NixOS).";
    };

    primaryGroup = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The primary group of every user (NixOS); the system's default when null.";
    };

    shell = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "pkgs.zsh";
      description = "The login shell of every user; the system's default when null.";
    };

    internal.baseDefaults = mkOption {
      type = types.functionTo types.attrs;
      internal = true;
      default = name: { inherit name; };
      description = "The defaults of a user of this kind of system, by name.";
    };
  };
}
