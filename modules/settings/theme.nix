{ config, lib, ... }:

with lib;
let
  cfg = config.soxin.settings.theme;
in
{
  options = {
    soxin.settings.theme = mkOption {
      type = with types; nullOr (enum (mapAttrsToList (n: _: n) config.soxin.themes));
      default = null;
      apply = value: if value == null then null else config.soxin.themes.${value};
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg != null;
        message = "soxin.settings.theme cannot be empty.";
      }
    ];
  };
}
