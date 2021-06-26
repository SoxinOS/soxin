{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.programmingLanguage = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.programmingLanguages));
      apply = value: config.soxin.programmingLanguages.${value};
    };
  };
}
