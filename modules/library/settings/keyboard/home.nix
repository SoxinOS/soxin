# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ config, lib, ... }:

let
  cfg = config.soxin.settings.keyboard;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.layouts != [ ]) {
    home.keyboard = {
      layout = lib.concatMapStringsSep "," (l: l.x11.layout) cfg.layouts;
      variant = lib.concatMapStringsSep "," (l: l.x11.variant) cfg.layouts;
    };
  };
}
