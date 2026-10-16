# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# The fleet flake-parts module. It reads a fleet directory (hosts, profiles and
# the fleet's own modules) into the `fleet` options and builds
# nixosConfigurations, darwinConfigurations, homeConfigurations, deploy-rs
# nodes and checks out of them.
{ soxin, soxinInputs }:
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
    concatMap
    filterAttrs
    genAttrs
    literalExpression
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkDefault
    mkIf
    mkOption
    nameValuePair
    optional
    optionals
    types
    unique
    ;

  cfg = config.fleet;

  # The frameworks the fleet is built with. A fleet input of the same name
  # wins over the one Soxin pins.
  frameworkInputs = [
    "home-manager"
    "nix-darwin"
    "deploy-rs"
    "sops-nix"
  ];

  # The file stem of each kind's module in a profile or modules directory.
  stems = {
    nixos = "nixos";
    darwin = "darwin";
    home-manager = "home";
  };

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

  hosts = cfg.hosts;
  hostsOfKind = kind: filterAttrs (_: host: host.kind == kind) hosts;

  # Every system a host runs on or the flake is evaluated for.
  allSystems = unique (config.systems ++ mapAttrsToList (_: host: host.system) hosts);

  # `channels.<system>.<channel>`: one nixpkgs per channel and system, each
  # with the shared overlays and its own. A channel's overlays receive every
  # channel of the same system, so one channel can take packages from another.
  channels = genAttrs allSystems (
    system:
    lib.fix (
      self:
      mapAttrs (
        _: channel:
        import channel.input {
          inherit system;
          config = cfg.channelsConfig // channel.config;
          overlays = cfg.sharedOverlays ++ channel.overlays self;
        }
      ) cfg.channels
    )
  );

  channelOf =
    name: host:
    if cfg.channels ? ${host.channel} then
      cfg.channels.${host.channel}
    else
      throw "fleet: host `${name}` uses channel `${host.channel}`, which is not in fleet.channels";

  pkgsOf = name: host: builtins.seq (channelOf name host) channels.${host.system}.${host.channel};

  profileModules =
    name: host: stem:
    concatMap (
      profile:
      if cfg.profiles ? ${profile} then
        cfg.profiles.${profile}.${stem}
      else
        throw "fleet: host `${name}` uses profile `${profile}`, which is not in fleet.profiles"
    ) (unique (cfg.defaultProfiles ++ host.profiles));

  # The fleet's modules and profiles for one kind of configuration of a host.
  sharedModules =
    name: host: stem:
    cfg.modules.${stem} ++ profileModules name host stem;

  specialArgsOf =
    name: host: scope: kind:
    {
      inherit inputs soxin;
      hostName = name;
      channels = channels.${host.system};
      mode = modes.${kind};
    }
    // cfg.specialArgs.global
    // cfg.specialArgs.${scope}
    // host.specialArgs;

  # home-manager inside a NixOS or nix-darwin host.
  homeManagerModule =
    name: host:
    { lib, ... }:
    {
      home-manager = {
        useGlobalPkgs = lib.mkDefault true;
        useUserPackages = lib.mkDefault true;
        extraSpecialArgs = specialArgsOf name host "home" "home-manager";
        sharedModules =
          sharedModules name host "home"
          ++ optional cfg.sops.enable cfg.inputs.sops-nix.homeManagerModules.sops;
      };
    };

  systemModule =
    name: host:
    { lib, ... }:
    {
      nixpkgs.pkgs = pkgsOf name host;
      networking.hostName = lib.mkDefault name;
    };

  build = {
    nixos =
      name: host:
      (channelOf name host).input.lib.nixosSystem {
        specialArgs = specialArgsOf name host "nixos" "nixos";
        modules = [
          (systemModule name host)
        ]
        ++ sharedModules name host "nixos"
        ++ host.modules
        ++ optional cfg.sops.enable cfg.inputs.sops-nix.nixosModules.sops
        ++ optionals cfg.homeManager.enable [
          cfg.inputs.home-manager.nixosModules.home-manager
          (homeManagerModule name host)
        ];
      };

    darwin =
      name: host:
      cfg.inputs.nix-darwin.lib.darwinSystem {
        inherit ((channelOf name host).input) lib;
        specialArgs = specialArgsOf name host "darwin" "darwin";
        modules = [
          (systemModule name host)
        ]
        ++ sharedModules name host "darwin"
        ++ host.modules
        ++ optional cfg.sops.enable cfg.inputs.sops-nix.darwinModules.sops
        ++ optionals cfg.homeManager.enable [
          cfg.inputs.home-manager.darwinModules.home-manager
          (homeManagerModule name host)
        ];
      };

    home-manager =
      name: host:
      cfg.inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsOf name host;
        extraSpecialArgs = specialArgsOf name host "home" "home-manager";
        modules =
          sharedModules name host "home"
          ++ host.modules
          ++ optional cfg.sops.enable cfg.inputs.sops-nix.homeManagerModules.sops;
      };
  };

  configurations = mapAttrs (name: host: build.${host.kind} name host) hosts;

  # What evaluating a host produces: the derivation deploy-rs activates.
  toplevel =
    name: host:
    let
      configuration = configurations.${name};
    in
    if host.kind == "home-manager" then
      configuration.activationPackage
    else
      configuration.config.system.build.toplevel;

  deployHosts = filterAttrs (_: host: host.deploy.hostname != null) hosts;

  deployNode =
    name: host:
    let
      activate = cfg.inputs.deploy-rs.lib.${host.system}.activate;
      configuration = configurations.${name};
      inherit (host.deploy) user;
    in
    assert lib.assertMsg (
      user != null
    ) "fleet: host `${name}` is deployed but has no deploy.user; a home-manager host must name one";
    {
      inherit (host.deploy) hostname;
      profiles.${host.deploy.profileName} = {
        inherit user;
        path =
          {
            nixos = activate.nixos configuration;
            darwin = activate.darwin configuration;
            home-manager = activate.home-manager configuration;
          }
          .${host.kind};
      };
    }
    // lib.optionalAttrs (host.deploy.sshUser != null) { inherit (host.deploy) sshUser; }
    // host.deploy.settings;

  deployNodes = mapAttrs deployNode deployHosts;
in
{
  options.fleet = {
    root = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./.";
      description = ''
        The fleet directory. `hostsDir`, `profilesDir` and `modulesDir` default
        to its `hosts`, `profiles` and `modules` subdirectories.
      '';
    };

    hostsDir = mkOption {
      type = types.nullOr types.path;
      default = if cfg.root == null then null else cfg.root + "/hosts";
      defaultText = literalExpression "root + \"/hosts\"";
      description = "A directory of hosts: every `<name>/host.nix` in it defines `fleet.hosts.<name>`.";
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

    inputs = genAttrs frameworkInputs (
      input:
      mkOption {
        type = types.raw;
        default = inputs.${input} or soxinInputs.${input};
        defaultText = literalExpression "inputs.${input} or soxin.inputs.${input}";
        description = "The ${input} flake the fleet is built with.";
      }
    );

    channels = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            input = mkOption {
              type = types.raw;
              description = "A nixpkgs flake.";
            };

            config = mkOption {
              type = types.attrsOf types.raw;
              default = { };
              description = "nixpkgs configuration of this channel, on top of `fleet.channelsConfig`.";
            };

            overlays = mkOption {
              type = types.functionTo (types.listOf types.raw);
              default = _: [ ];
              example = literalExpression ''
                channels: [
                  (final: prev: { inherit (channels.nixpkgs-unstable) hello; })
                ]
              '';
              description = ''
                A function from every channel of the same system to the
                overlays of this channel, applied after `fleet.sharedOverlays`.
              '';
            };
          };
        }
      );
      default = { };
      description = "The nixpkgs channels hosts can use.";
    };

    defaultChannel = mkOption {
      type = types.str;
      default = "nixpkgs";
      description = "The channel of a host that does not name one.";
    };

    channelsConfig = mkOption {
      type = types.attrsOf types.raw;
      default = { };
      example = {
        allowUnfree = true;
      };
      description = "nixpkgs configuration shared by every channel.";
    };

    sharedOverlays = mkOption {
      type = types.listOf types.raw;
      default = [ ];
      description = "Overlays applied to every channel.";
    };

    modules = kindOptions "Modules imported by every host of that kind; `home` ones go to standalone home-manager hosts and to home-manager inside NixOS and nix-darwin hosts";

    specialArgs = argsOptions "Extra arguments passed to the modules of that kind; `global` ones to every kind";

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

    checks = {
      hosts = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to add a `host-<name>` check per host that evaluates it. The
          check builds nothing but a marker file, so it works for hosts of any
          system.
        '';
      };

      deploySchema = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to check the deploy-rs nodes against the deploy-rs schema.";
      };
    };

    hosts = mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ (import ./host.nix { inherit (cfg) defaultChannel; }) ];
          specialArgs = { inherit inputs; };
        }
      );
      default = { };
      description = "The hosts of the fleet.";
    };

    configurations = mkOption {
      type = types.lazyAttrsOf types.raw;
      readOnly = true;
      description = "Every host's evaluated configuration, by host name.";
    };
  };

  config = {
    fleet = {
      channels.nixpkgs.input = mkDefault (inputs.nixpkgs or soxinInputs.nixpkgs);

      hosts = genAttrs (subdirectories cfg.hostsDir) (
        name:
        let
          file = cfg.hostsDir + "/${name}/host.nix";
        in
        if pathExists file then file else throw "fleet: ${toString cfg.hostsDir}/${name} has no host.nix"
      );

      profiles = genAttrs (subdirectories cfg.profilesDir) (
        name: genAttrs [ "nixos" "darwin" "home" ] (kindModule (cfg.profilesDir + "/${name}"))
      );

      modules = genAttrs [ "nixos" "darwin" "home" ] (kindModule cfg.modulesDir);

      inherit configurations;
    };

    flake = {
      nixosConfigurations = mapAttrs (name: _: configurations.${name}) (hostsOfKind "nixos");
      darwinConfigurations = mapAttrs (name: _: configurations.${name}) (hostsOfKind "darwin");
      homeConfigurations = mapAttrs (name: _: configurations.${name}) (hostsOfKind "home-manager");
      deploy = mkIf (deployNodes != { }) { nodes = deployNodes; };
    };

    perSystem =
      { system, ... }:
      let
        pkgs = channels.${system}.${cfg.defaultChannel};

        hostChecks = mapAttrs' (
          name: host:
          nameValuePair "host-${name}" (
            pkgs.runCommandLocal "fleet-host-${name}" {
              toplevel = builtins.unsafeDiscardStringContext (toplevel name host).drvPath;
            } ''echo "$toplevel" > "$out"''
          )
        ) hosts;

        # deploy-rs's own deployChecks build every node's closure, which a
        # machine of another system cannot do; this checks the schema alone.
        deploySchemaCheck =
          let
            nodes = mapAttrs (
              _: node:
              node
              // {
                profiles = mapAttrs (
                  _: profile: profile // { path = builtins.unsafeDiscardStringContext profile.path.drvPath; }
                ) node.profiles;
              }
            ) deployNodes;
            python = pkgs.python3.withPackages (ps: [ ps.jsonschema ]);
          in
          pkgs.runCommandLocal "fleet-deploy-schema"
            {
              deploy = builtins.toJSON { inherit nodes; };
              passAsFile = [ "deploy" ];
              schema = "${cfg.inputs.deploy-rs}/interface.json";
            }
            ''
              ${python.interpreter} -c '
              import json, sys, jsonschema
              jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))
              ' "$deployPath" "$schema"
              touch "$out"
            '';
      in
      {
        _module.args.pkgs = mkDefault pkgs;

        checks =
          lib.optionalAttrs cfg.checks.hosts hostChecks
          // lib.optionalAttrs (cfg.checks.deploySchema && deployNodes != { }) {
            deploy-schema = deploySchemaCheck;
          };
      };
  };
}
