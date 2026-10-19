# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ config, lib, ... }:

let
  inherit (lib)
    filter
    mapAttrs
    mkIf
    optionalAttrs
    optionals
    ;

  cfg = config.soxin.settings.users;

  makeUser =
    _:
    { isAdmin, sshKeys, ... }@user:
    optionalAttrs (cfg.primaryGroup != null) { group = cfg.primaryGroup; }
    // {
      extraGroups = cfg.defaultGroups ++ cfg.groups ++ optionals isAdmin [ "wheel" ];
    }
    // optionalAttrs (cfg.shell != null) { inherit (cfg) shell; }
    // {
      isNormalUser = true;
      openssh.authorizedKeys.keys = sshKeys;
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
      home = "/home/${name}";
      isAdmin = false;
      isNixTrustedUser = false;
      sshKeys = [ ];
    };

    users.users = mkIf cfg.enable (mapAttrs makeUser cfg.users);

    nix.settings.trusted-users = mkIf cfg.enable (
      [ "root" ]
      ++ map (user: user.name) (filter (user: user.isNixTrustedUser) (builtins.attrValues cfg.users))
    );
  };
}
