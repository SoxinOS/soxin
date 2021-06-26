{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.programmingLanguages = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.programmingLanguagesInternal));
      apply = value: config.soxin.programmingLanguagesInternal.${value};
    };
  };
}

