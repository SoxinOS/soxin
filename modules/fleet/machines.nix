# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# NixOS and nix-darwin machines on Clan. Clan discovers `machines/<name>/`,
# builds the machines and deploys them (`clan machines update`); Soxin makes
# each `nixos` or `darwin` host a Clan machine of that class and adds its
# channel's packages, the fleet's modules and profiles, home-manager,
# sops-nix and the pinned inputs.
{ modules, ... }:
{ config, lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkDefault
    mkIf
    optional
    ;

  cfg = config.fleet;
  inherit (cfg.internal)
    kindArgs
    hostArgs
    pkgsOf
    modulesOf
    ;

  stems = {
    nixos = "nixos";
    darwin = "darwin";
  };

  machines = filterAttrs (_: host: host.kind != "home-manager") cfg.hosts;

  # home-manager inside a NixOS or nix-darwin machine.
  homeManagerModule =
    name: host:
    { lib, ... }:
    {
      home-manager = {
        useGlobalPkgs = lib.mkDefault true;
        useUserPackages = lib.mkDefault true;
        extraSpecialArgs = kindArgs "home-manager" "home" // hostArgs name host;
        sharedModules =
          modulesOf name host "home" ++ optional cfg.sops.enable cfg.inputs.sops-nix.homeManagerModules.sops;
      };
    };

  machineModule =
    name: host:
    let
      inherit (host) kind;
    in
    {
      _file = "${toString ./machines.nix}#${name}";

      # The fleet's modules and profiles come first and the host's own last,
      # so the host's list definitions follow the fleet's.
      imports =
        modulesOf name host stems.${kind}
        ++ optional cfg.homeManager.enable (homeManagerModule name host)
        ++ optional (cfg.pinInputs.registry || cfg.pinInputs.nixPath) cfg.pinInputs.module
        ++ host.modules
        ++ optional cfg.sops.enable cfg.inputs.sops-nix."${kind}Modules".sops
        ++ optional cfg.homeManager.enable cfg.inputs.home-manager."${kind}Modules".home-manager;

      config = {
        _module.args = hostArgs name host;
        nixpkgs.pkgs = pkgsOf name host;
      };
    };
in
{
  imports = [
    modules.hosts
    modules.clan-builders
    modules.pin-inputs
  ];

  config = {
    fleet.configurations =
      mapAttrs (name: _: config.flake.nixosConfigurations.${name}) (
        filterAttrs (_: host: host.kind == "nixos") machines
      )
      // mapAttrs (name: _: config.flake.darwinConfigurations.${name}) (
        filterAttrs (_: host: host.kind == "darwin") machines
      );

    flake.clan = {
      directory = mkIf (cfg.root != null) (mkDefault cfg.root);

      # Clan requires a name; a fleet sets its own with `clan.meta.name`.
      meta.name = mkDefault "fleet";

      inventory.machines = mapAttrs (_: host: { machineClass = host.kind; }) machines;

      machines = mapAttrs machineModule machines;
    };

    perSystem =
      { system, ... }:
      {
        # Clan's per-system packages: the default channel, overlays included.
        clan.pkgs = mkDefault cfg.packages.${system}.${cfg.defaultChannel};
      };
  };
}
