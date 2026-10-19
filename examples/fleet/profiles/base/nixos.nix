# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "UTC";

  # Shared settings of Soxin's library, which programs read.
  soxin.settings.keyboard.layouts = [ { x11.layout = "us"; } ];
  soxin.settings.theme = "gruvbox-dark";
}
