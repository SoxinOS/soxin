# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# A module of the fleet's own: every home-manager configuration gets it.
{ config, lib, ... }:
{
  options.example.greeting = lib.mkOption {
    type = lib.types.str;
    default = "Hello";
    description = "A line written to ~/.greeting.";
  };

  config.home.file.".greeting".text = config.example.greeting + "\n";
}
