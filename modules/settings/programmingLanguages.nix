{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.progammingLanguages = mkOption {
      type = with types; nullOr (enum (mapAttrsToList (n: _: n) config.soxin.programmingLanguages));
      apply = value: config.soxin.programmingLanguages.${value};
    };
  };
}
