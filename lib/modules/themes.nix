{ lib }:

let
  inherit (lib)
    mkOption
    types
  ;
in
rec {
  themeModule = types.submodule {
    options = {
      rofi = mkOption {
        type = rofiModule;
        default = { };
      };
    };
  };

  rofiModule = types.submodule {
    options = {
      name = mkOption {
        type = with types; nullOr str;
        default = null;
      };
    };
  };
}
