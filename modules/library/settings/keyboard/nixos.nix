# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ config, lib, ... }:

let
  cfg = config.soxin.settings.keyboard;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.layouts != [ ]) {
    console = {
      inherit (cfg.defaultLayout.console) keyMap;
      earlySetup = cfg.enableAtBoot;
    };

    services.xserver = {
      xkb.layout = lib.concatMapStringsSep "," (l: l.x11.layout) cfg.layouts;
      xkb.variant = lib.concatMapStringsSep "," (l: l.x11.variant) cfg.layouts;
    };
  };
}
