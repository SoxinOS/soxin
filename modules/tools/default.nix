{ soxin, config, lib, ... }:

with lib;
{
  options = {
    soxin.tools = mkOption {
      type = with types; soxin.lib.modules.tools.toolsModule;
      default = {  };
    };
  };

  imports = [
    # import individual tools here
  ];
}
