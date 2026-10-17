# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# A `host-<name>` check per host that evaluates it down to its toplevel (or a
# home's activation package) derivation. It builds nothing but a marker file,
# so `nix flake check` on any machine evaluates hosts of every system.
{ modules, ... }:
{ config, lib, ... }:

let
  cfg = config.fleet;

  toplevel =
    name: host:
    let
      configuration = cfg.configurations.${name};
    in
    if host.kind == "home-manager" then
      configuration.activationPackage
    else
      configuration.config.system.build.toplevel;
in
{
  imports = [ modules.hosts ];

  options.fleet.checks.hosts = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to add a `host-<name>` check per host that evaluates it.";
  };

  config.perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs cfg.checks.hosts (
        lib.mapAttrs' (
          name: host:
          lib.nameValuePair "host-${name}" (
            pkgs.runCommandLocal "fleet-host-${name}" {
              toplevel = builtins.unsafeDiscardStringContext (toplevel name host).drvPath;
            } ''echo "$toplevel" > "$out"''
          )
        ) cfg.hosts
      );
    };
}
