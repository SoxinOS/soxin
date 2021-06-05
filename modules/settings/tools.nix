{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.tools = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.tools));
      apply = value: config.soxin.tools.${value};
    };
  };
}
