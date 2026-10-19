# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's module library (settings.users, settings.keyboard, settings.theme,
# hardware.yubikey, hardware.serial_console) on every host, before the
# fleet's own modules. Its modules configure nothing until enabled or set, and
# it is not part of the fleet's exported modules.
{ modules, ... }:
{ config, lib, ... }:

let
  library = import ../library;
in
{
  imports = [ modules.profiles ];

  options.fleet.library.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether every host imports Soxin's module library first. A fleet that
      places the library's modules itself (`soxin.lib.library`) turns it off.
    '';
  };

  config.fleet.internal.libraryModules = lib.mkIf config.fleet.library.enable {
    nixos = [ library.nixos.soxin ];
    darwin = [ library.darwin.soxin ];
    home = [ library.home.soxin ];
  };
}
