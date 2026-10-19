# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's module library (settings.users, settings.keyboard, settings.theme,
# hardware.yubikey, hardware.serial_console) on every host, before the
# fleet's own modules. Its modules configure nothing until enabled or set, and
# it is not part of the fleet's exported modules.
{ modules, ... }:
_:

let
  library = import ../library;
in
{
  imports = [ modules.profiles ];

  config.fleet.internal.libraryModules = {
    nixos = [ library.nixos.soxin ];
    darwin = [ library.darwin.soxin ];
    home = [ library.home.soxin ];
  };
}
