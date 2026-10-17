# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# The hosts of the fleet and what every kind of configuration shares: the
# frameworks it is built with, sops-nix as an opt-in, and the module
# arguments (`inputs`, `soxin`, `hostName`, `channels`, `mode` and
# `fleet.specialArgs`). Machines and homes build on it.
{
  soxin,
  soxinInputs,
  modules,
}:
{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (builtins) pathExists readDir;

  inherit (lib)
    attrNames
    filterAttrs
    genAttrs
    literalExpression
    mkDefault
    mkOption
    types
    ;

  cfg = config.fleet;

  # The frameworks the fleet is built with. A fleet input of the same name
  # wins over the one Soxin pins.
  frameworkInputs = [
    "home-manager"
    "nix-darwin"
    "sops-nix"
  ];

  # The value `mode` takes in each kind's modules; the names are the ones v1
  # used, so modules that switch on `mode` keep working.
  modes = {
    nixos = "NixOS";
    darwin = "nix-darwin";
    home-manager = "home-manager";
  };

  subdirectories =
    dir:
    if dir != null && pathExists dir then
      attrNames (filterAttrs (_: type: type == "directory") (readDir dir))
    else
      [ ];

  # The `<name>/host.nix` of every directory in `dir`, as host modules whose
  # `kind` defaults to `defaultKind`.
  hostFiles =
    dir: defaultKind:
    genAttrs (subdirectories dir) (
      name:
      let
        file = dir + "/${name}/host.nix";
      in
      if pathExists file then
        {
          imports = [ file ];
          kind = mkDefault defaultKind;
        }
      else
        throw "fleet: ${toString dir}/${name} has no host.nix"
    );

  argsOptions =
    description:
    genAttrs [ "global" "nixos" "darwin" "home" ] (
      scope:
      mkOption {
        type = types.attrsOf types.raw;
        default = { };
        description = "${description} (${scope}).";
      }
    );

  kindArgs =
    kind: scope:
    {
      inherit inputs soxin;
      mode = modes.${kind};
    }
    // cfg.specialArgs.global
    // cfg.specialArgs.${scope};

  hostArgs =
    name: host:
    {
      hostName = name;
      channels = cfg.packages.${host.system};
    }
    // host.specialArgs;

  internal =
    description: type:
    mkOption {
      inherit type description;
      readOnly = true;
      internal = true;
    };
in
{
  imports = [
    modules.channels
    modules.profiles
  ];

  options.fleet = {
    homesDir = mkOption {
      type = types.nullOr types.path;
      default = if cfg.root == null then null else cfg.root + "/homes";
      defaultText = literalExpression "root + \"/homes\"";
      description = "A directory of standalone home-manager hosts: every `<name>/host.nix` in it defines `fleet.hosts.<name>`.";
    };

    inputs = genAttrs frameworkInputs (
      input:
      mkOption {
        type = types.raw;
        default = inputs.${input} or soxinInputs.${input};
        defaultText = literalExpression "inputs.${input} or soxin.inputs.${input}";
        description = "The ${input} flake the fleet is built with.";
      }
    );

    specialArgs = argsOptions "Extra arguments passed to the modules of that kind; `global` ones to every kind";

    homeManager.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add the home-manager module to NixOS and nix-darwin hosts.";
    };

    sops.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to add the sops-nix module to NixOS, nix-darwin and home-manager configurations.";
    };

    hosts = mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ (import ./host.nix { inherit (cfg) defaultChannel; }) ];
          specialArgs = { inherit inputs; };
        }
      );
      default = { };
      description = ''
        The hosts of the fleet. `nixos` and `darwin` hosts are Clan machines,
        which Clan builds; `home-manager` hosts are built by Soxin.
      '';
    };

    configurations = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
      description = "Every host's evaluated configuration, by host name.";
    };

    internal = {
      kindArgs = internal "`kind: scope:` the arguments every module of a kind gets, usable in `imports`: the framework's, then `fleet.specialArgs.global`, then the scope's." (
        types.functionTo (types.functionTo (types.attrsOf types.raw))
      );
      hostArgs = internal "`name: host:` a host's own arguments: its name, its system's channels and its `specialArgs`." (
        types.functionTo (types.functionTo (types.attrsOf types.raw))
      );
      pkgsOf = internal "`name: host:` the packages of a host's channel." (
        types.functionTo (types.functionTo types.raw)
      );
    };
  };

  config.fleet = {
    hosts =
      hostFiles (if cfg.root == null then null else cfg.root + "/machines") "nixos"
      // hostFiles cfg.homesDir "home-manager";

    internal = {
      inherit kindArgs hostArgs;
      pkgsOf =
        name: host:
        if cfg.channels ? ${host.channel} then
          cfg.packages.${host.system}.${host.channel}
        else
          throw "fleet: host `${name}` uses channel `${host.channel}`, which is not in fleet.channels";
    };
  };
}
