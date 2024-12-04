{
  soxin,
  config,
  lib,
  ...
}:

with lib;
{
  options = {
    soxin.programmingLanguages = mkOption {
      type = with types; attrsOf soxin.lib.modules.programmingLanguages.programmingLanguages;
      default = { };
    };
  };

  imports = [ ./go/default.nix ];
}
