# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Standalone home-manager hosts (`homes/<name>/`), which Clan does not build:
# `kind = "home-manager"` hosts become `homeConfigurations.<name>`. Usable
# without Clan.
{ modules, ... }:
{ config, lib, ... }:

let
  inherit (lib) filterAttrs mapAttrs optional;

  cfg = config.fleet;
  inherit (cfg.internal) kindArgs hostArgs pkgsOf;

  homes = filterAttrs (_: host: host.kind == "home-manager") cfg.hosts;

  homeConfiguration =
    name: host:
    cfg.inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsOf name host;
      extraSpecialArgs = kindArgs "home-manager" "home" // hostArgs name host;
      modules =
        cfg.internal.modulesOf name host "home"
        ++ host.modules
        ++ optional cfg.sops.enable cfg.inputs.sops-nix.homeManagerModules.sops;
    };

  configurations = mapAttrs homeConfiguration homes;
in
{
  imports = [ modules.hosts ];

  config = {
    fleet.configurations = configurations;
    flake.homeConfigurations = configurations;
  };
}
