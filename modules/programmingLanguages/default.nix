{ soxin, config, lib, ... }:

with lib;
{
  options = {
    soxin.programmingLanguages = mkOption {
      type = with types; soxin.lib.modules.programming.programmingLanguagesModule;
      default = {  };
    };
  };

  imports = [
  	./go.nix
  ];
}
