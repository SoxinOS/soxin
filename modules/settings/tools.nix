{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.tools = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.tools));
      default = [ ];
      apply = value: map (v: config.soxin.tools.${v}) value;
    };
  };
}
