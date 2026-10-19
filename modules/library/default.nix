# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's module library. Every module is `<area>/<name>/` with an
# options.nix and a nixos.nix, darwin.nix and home.nix, each importing the
# options, so shared configuration can set them on every kind.
#
# `modules.<kind>.<area>-<name>` is one module of a kind, by path (so
# importing it twice declares it once), and `modules.<kind>.soxin` is all of
# them.
let
  library = [
    "hardware/serial_console"
    "hardware/yubikey"
    "settings/keyboard"
    "settings/theme"
    "settings/users"
  ];

  name = builtins.replaceStrings [ "/" "_" ] [ "-" "-" ];

  kind =
    kind:
    builtins.listToAttrs (
      map (module: {
        name = name module;
        value = ./. + "/${module}/${kind}.nix";
      }) library
    )
    // {
      soxin.imports = map (module: ./. + "/${module}/${kind}.nix") library;
    };
in
{
  nixos = kind "nixos";
  darwin = kind "darwin";
  home = kind "home";
}
