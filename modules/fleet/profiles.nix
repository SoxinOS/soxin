# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Profiles and the fleet's own modules, split by kind (nixos, darwin, home),
# and, on request, the same modules as flake outputs. Usable on its own.
_:
{ config, lib, ... }:

let
  inherit (builtins) pathExists readDir;

  inherit (lib)
    attrNames
    filterAttrs
    genAttrs
    literalExpression
    mapAttrs'
    mkIf
    mkOption
    nameValuePair
    optionalAttrs
    types
    ;

  cfg = config.fleet;

  subdirectories =
    dir:
    if dir != null && pathExists dir then
      attrNames (filterAttrs (_: type: type == "directory") (readDir dir))
    else
      [ ];

  # `<dir>/<stem>.nix` or `<dir>/<stem>/default.nix`, whichever exists.
  kindModule =
    dir: stem:
    let
      file = dir + "/${stem}.nix";
      directory = dir + "/${stem}/default.nix";
    in
    if dir == null then
      [ ]
    else if pathExists file then
      [ file ]
    else if pathExists directory then
      [ directory ]
    else
      [ ];

  kindOptions =
    description:
    genAttrs [ "nixos" "darwin" "home" ] (
      stem:
      mkOption {
        type = types.listOf types.raw;
        default = [ ];
        description = "${description} (${stem}).";
      }
    );

  # The modules of one kind as flake outputs: `default` for the fleet's own
  # modules and `profile-<name>` for each profile that has that kind.
  moduleOutputs =
    stem:
    optionalAttrs (cfg.modules.${stem} != [ ]) { default.imports = cfg.modules.${stem}; }
    // mapAttrs' (name: profile: nameValuePair "profile-${name}" { imports = profile.${stem}; }) (
      filterAttrs (_: profile: profile.${stem} != [ ]) cfg.profiles
    );
in
{
  options.fleet = {
    root = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./.";
      description = ''
        The fleet directory, which is also Clan's directory: its `machines/`
        holds the NixOS and nix-darwin machines, and `homesDir`, `profilesDir`
        and `modulesDir` default to its `homes`, `profiles` and `modules`
        subdirectories.
      '';
    };

    profilesDir = mkOption {
      type = types.nullOr types.path;
      default = if cfg.root == null then null else cfg.root + "/profiles";
      defaultText = literalExpression "root + \"/profiles\"";
      description = ''
        A directory of profiles: every `<name>/` in it defines
        `fleet.profiles.<name>` from its `nixos.nix`, `darwin.nix` and
        `home.nix` (or `nixos/`, `darwin/` and `home/` directories).
      '';
    };

    modulesDir = mkOption {
      type = types.nullOr types.path;
      default = if cfg.root == null then null else cfg.root + "/modules";
      defaultText = literalExpression "root + \"/modules\"";
      description = ''
        The fleet's own modules: its `nixos.nix`, `darwin.nix` and `home.nix`
        (or `nixos/`, `darwin/` and `home/` directories) go into
        `fleet.modules`.
      '';
    };

    modules = kindOptions "Modules imported by every host of that kind; `home` ones go to standalone home-manager hosts and to home-manager inside NixOS and nix-darwin hosts";

    profiles = mkOption {
      type = types.attrsOf (types.submodule { options = kindOptions "Modules of the profile"; });
      default = { };
      description = "Bundles of settings that hosts take by name.";
    };

    defaultProfiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "base" ];
      description = "Profiles every host takes.";
    };

    exportModules = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to expose the fleet's modules and profiles as flake outputs:
        `nixosModules`, `darwinModules` and `homeModules`, each with
        `default` (the fleet's own modules of that kind) and
        `profile-<name>` (a profile's modules of that kind).
      '';
    };

    internal.modulesOf = mkOption {
      type = types.functionTo (types.functionTo (types.functionTo (types.listOf types.raw)));
      readOnly = true;
      internal = true;
      description = "`name: host: stem:` the fleet's modules and the host's profiles of one kind.";
    };
  };

  config = {
    fleet = {
      profiles = genAttrs (subdirectories cfg.profilesDir) (
        name: genAttrs [ "nixos" "darwin" "home" ] (kindModule (cfg.profilesDir + "/${name}"))
      );

      modules = genAttrs [ "nixos" "darwin" "home" ] (kindModule cfg.modulesDir);

      internal.modulesOf =
        name: host: stem:
        cfg.modules.${stem}
        ++ lib.concatMap (
          profile:
          if cfg.profiles ? ${profile} then
            cfg.profiles.${profile}.${stem}
          else
            throw "fleet: host `${name}` uses profile `${profile}`, which is not in fleet.profiles"
        ) (lib.unique (cfg.defaultProfiles ++ host.profiles));
    };

    flake = mkIf cfg.exportModules {
      nixosModules = moduleOutputs "nixos";
      darwinModules = moduleOutputs "darwin";
      homeModules = moduleOutputs "home";
    };
  };
}
