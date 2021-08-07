{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.programmingLanguages = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.programmingLanguagesModules));
      default = [ ];
      apply = value: map
        (v:
          config.soxin.programmingLanguagesModules.${v}
        )
        value;
    };
  };
}

