{ lib, ... }:

with lib;
{
  options = {
    soxin.utils = mkOption {
      type = types.attrs;
      default = { };
    };
  };
}
