{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.theme = mkOption {
      type = with types; nullOr (enum (mapAttrsToList (n: _: n) config.soxin.themes));
      apply = value: config.soxin.themes.${value};
    };
  };
}
