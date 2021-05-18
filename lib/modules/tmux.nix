{ lib }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

in
{
  pluginWithConfigModule = types.submodule {
    options = {
      plugin = mkOption {
        type = types.package;
        description = "Path of the configuration file to include.";
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration for the associated plugin.";
        default = "";
      };
    };
  };
}
