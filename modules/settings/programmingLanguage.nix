{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.programmingLanguage = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.programmingLanguages));
      default = [ ];
      #apply = value: config.soxin.programmingLanguages.${value};
      apply = value: map
        (v:
          config.soxin.programmingLanguages.${v}
        )
        value;
    };
  };
}

