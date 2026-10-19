# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ config, lib, ... }:

let
  inherit (lib) mapAttrs mkIf optionalAttrs;

  cfg = config.soxin.settings.users;

  makeUser =
    _: user:
    optionalAttrs (cfg.shell != null) { inherit (cfg) shell; }
    // {
      openssh.authorizedKeys.keys = user.sshKeys;
    }
    // builtins.removeAttrs user [
      "isAdmin"
      "isNixTrustedUser"
      "sshKeys"
    ];
in
{
  imports = [ ./options.nix ];

  config = {
    soxin.settings.users.internal.baseDefaults = name: {
      inherit name;
      home = "/Users/${name}";
    };

    users.users = mkIf cfg.enable (mapAttrs makeUser cfg.users);
  };
}
