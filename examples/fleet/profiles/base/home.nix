# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ pkgs, ... }:
{
  # hello comes from nixpkgs-unstable through the overlay in fleet.nix.
  home.packages = [ pkgs.hello ];

  programs.git.enable = true;
}
