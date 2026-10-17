# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# The fleet flake-parts module: Soxin's layer on Clan.
#
# Clan discovers the NixOS and nix-darwin machines (`machines/<name>/`) and
# builds them. This layer adds what Clan lacks: nixpkgs channels whose
# overlays see every channel, standalone home-manager hosts (`homes/<name>/`),
# profiles and the fleet's own modules split by kind, the `inputs`, `soxin`,
# `hostName`, `channels` and `mode` module arguments, sops-nix as an opt-in,
# deploy-rs nodes and evaluation checks.
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
    functionArgs
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
    setFunctionArgs
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
  machines = filterAttrs (_: host: host.kind != "home-manager") hosts;
  homes = hostsOfKind "home-manager";

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

  # The arguments every module of a kind gets, usable in `imports`: the
  # framework's, then `fleet.specialArgs.global`, then the kind's.
  kindArgs =
    kind: scope:
    {
      inherit inputs soxin;
      mode = modes.${kind};
    }
    // cfg.specialArgs.global
    // cfg.specialArgs.${scope};

  # The arguments of one host: its name, its system's channels and its own
  # `specialArgs`.
  hostArgs =
    name: host:
    {
      hostName = name;
      channels = channels.${host.system};
    }
    // host.specialArgs;

  specialArgsOf =
    name: host: scope: kind:
    kindArgs kind scope // hostArgs name host;

  # Clan builds every machine with `nixpkgs.lib.nixosSystem` or
  # `nix-darwin.lib.darwinSystem`, both taken from the flake's inputs, and
  # passes the same special arguments to every machine. Soxin hands Clan the
  # fleet's nixpkgs and nix-darwin with those two functions wrapped, so each
  # kind gets its own `mode` and `fleet.specialArgs`, which modules may use in
  # `imports`. A host's own arguments vary per machine and reach its modules
  # as module arguments instead (see `machineModule`).
  constructors =
    let
      nixpkgs = cfg.channels.${cfg.defaultChannel}.input;
      nix-darwin = cfg.inputs.nix-darwin;
      withArgs =
        kind: scope: build: args:
        build (args // { specialArgs = (args.specialArgs or { }) // kindArgs kind scope; });
    in
    {
      nixpkgs = nixpkgs // {
        lib = nixpkgs.lib // {
          nixosSystem = withArgs "nixos" "nixos" nixpkgs.lib.nixosSystem;
        };
      };
      nix-darwin = nix-darwin // {
        lib = nix-darwin.lib // {
          darwinSystem = withArgs "darwin" "darwin" nix-darwin.lib.darwinSystem;
        };
      };
    };

  clanFlakeModule = (inputs.clan-core or soxinInputs.clan-core).flakeModules.default;

  # Clan's flake-parts module, seeing `constructors` in place of the flake's
  # own nixpkgs and nix-darwin inputs.
  clanModule = {
    _file = "${toString ./default.nix}#clan";
    imports = [
      (setFunctionArgs (args: clanFlakeModule (args // { inputs = args.inputs // constructors; })) (
        functionArgs clanFlakeModule
      ))
    ];
  };

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

  # What Soxin adds to a Clan machine.
  machineModule =
    name: host:
    let
      inherit (host) kind;
    in
    {
      _file = "${toString ./default.nix}#machine-${name}";

      # The fleet's modules and profiles come first and the host's own last,
      # so the host's list definitions follow the fleet's.
      imports =
        sharedModules name host stems.${kind}
        ++ optional cfg.homeManager.enable (homeManagerModule name host)
        ++ host.modules
        ++ optional cfg.sops.enable cfg.inputs.sops-nix."${kind}Modules".sops
        ++ optional cfg.homeManager.enable cfg.inputs.home-manager."${kind}Modules".home-manager;

      config = {
        _module.args = hostArgs name host;
        nixpkgs.pkgs = pkgsOf name host;
      };
    };

  homeConfiguration =
    name: host:
    cfg.inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsOf name host;
      extraSpecialArgs = specialArgsOf name host "home" "home-manager";
      modules =
        sharedModules name host "home"
        ++ host.modules
        ++ optional cfg.sops.enable cfg.inputs.sops-nix.homeManagerModules.sops;
    };

  configurations =
    mapAttrs (name: _: config.flake.nixosConfigurations.${name}) (hostsOfKind "nixos")
    // mapAttrs (name: _: config.flake.darwinConfigurations.${name}) (hostsOfKind "darwin")
    // mapAttrs homeConfiguration homes;

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

  machinesDir = if cfg.root == null then null else cfg.root + "/machines";
in
{
  imports = [ clanModule ];

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

    homesDir = mkOption {
      type = types.nullOr types.path;
      default = if cfg.root == null then null else cfg.root + "/homes";
      defaultText = literalExpression "root + \"/homes\"";
      description = "A directory of standalone home-manager hosts: every `<name>/host.nix` in it defines `fleet.hosts.<name>`.";
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
      description = ''
        The nixpkgs channels hosts can use. A host's packages come from its
        channel. The NixOS and nix-darwin modules of every machine come from
        the default channel's nixpkgs, which Clan builds all machines with.
      '';
    };

    defaultChannel = mkOption {
      type = types.str;
      default = "nixpkgs";
      description = "The channel of a host that names none, and the nixpkgs Clan builds machines with.";
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
      description = ''
        The hosts of the fleet. `nixos` and `darwin` hosts are Clan machines,
        which Clan builds; `home-manager` hosts are built by Soxin.
      '';
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

      hosts = hostFiles machinesDir "nixos" // hostFiles cfg.homesDir "home-manager";

      profiles = genAttrs (subdirectories cfg.profilesDir) (
        name: genAttrs [ "nixos" "darwin" "home" ] (kindModule (cfg.profilesDir + "/${name}"))
      );

      modules = genAttrs [ "nixos" "darwin" "home" ] (kindModule cfg.modulesDir);

      inherit configurations;
    };

    flake = {
      clan = {
        directory = mkIf (cfg.root != null) (mkDefault cfg.root);

        # Clan requires a name; a fleet sets its own with `clan.meta.name`.
        meta.name = mkDefault "fleet";

        inventory.machines = mapAttrs (_: host: { machineClass = host.kind; }) machines;

        machines = mapAttrs machineModule machines;
      };

      homeConfigurations = mapAttrs (name: _: configurations.${name}) homes;
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

        # Clan's per-system packages: the default channel, overlays included.
        clan.pkgs = mkDefault pkgs;

        checks =
          lib.optionalAttrs cfg.checks.hosts hostChecks
          // lib.optionalAttrs (cfg.checks.deploySchema && deployNodes != { }) {
            deploy-schema = deploySchemaCheck;
          };
      };
  };
}
