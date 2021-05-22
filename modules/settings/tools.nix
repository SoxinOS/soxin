{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.tools = mkOption {
      type = with types; nullOr (enum (mapAttrsToList (n: _: n) config.soxin.tools));
      apply = value: config.soxin.tools.${value};
    };
  };
}
