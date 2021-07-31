{ soxin, config, lib, ... }:

with lib;
{
  options = {
    soxin.programmingLanguagesModules = mkOption {
      type = with types; attrsOf soxin.lib.modules.programmingLanguages.programmingLanguagesModule;
      default = { };
    };
  };

  imports = [
    ./go/default.nix
  ];
}
