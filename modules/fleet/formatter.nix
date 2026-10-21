# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# One formatter for the flake that imports it: deadnix, statix and nixfmt,
# through treefmt-nix. `nix fmt` runs treefmt's wrapper, and so does the
# `treefmt` hook of git-hooks.nix, so a commit that passes the hook is one
# `nix fmt` leaves alone, and the other way round. Both check the importing
# flake's own files (`self`).
#
# A flake adds formatters with `perSystem.treefmt` and hooks with
# `perSystem.pre-commit.settings.hooks`, and gets the hook installed by its
# development shell with `inputsFrom = [ config.pre-commit.devShell ]`.
{ soxinInputs, ... }:
{ lib, ... }:
{
  imports = [
    soxinInputs.treefmt-nix.flakeModule
    soxinInputs.git-hooks.flakeModule
  ];

  perSystem =
    { config, ... }:
    {
      treefmt = {
        projectRootFile = lib.mkDefault "flake.nix";
        programs = {
          deadnix.enable = lib.mkDefault true;
          nixfmt.enable = lib.mkDefault true;
          statix.enable = lib.mkDefault true;
        };
      };

      pre-commit.settings.hooks.treefmt = {
        enable = lib.mkDefault true;
        packageOverrides.treefmt = config.treefmt.build.wrapper;
      };
    };
}
