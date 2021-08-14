{ soxin, config, lib, ... }:

with lib;
{
  options = {
    soxin.tools = mkOption {
      type = with types; attrsOf soxin.lib.modules.tools.toolsModule;
      default = { };
    };
  };

  imports = [
    ./git/default.nix
  ];
}
