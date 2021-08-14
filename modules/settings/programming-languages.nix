{ config, lib, ... }:

with lib;
{
  options = {
    soxin.settings.programmingLanguages = mkOption {
      type = with types; listOf (enum (mapAttrsToList (n: _: n) config.soxin.programmingLanguages));
      default = [ ];
      apply = value: map
        (v:
          config.soxin.programmingLanguages.${v}
        )
        value;
    };
  };
}

