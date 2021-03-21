{ config, lib, ... }:

with lib;
let
  themeModule = types.submodule {
    options = {
      rofi = mkOption {
        type = with types; nullOr rofiModule;
        default = null;
      };
    };
  };
in
{
  options = {
    soxin.themes = mkOption {
      type = with types; attrsOf themeModule;
      default = { };
    };
  };

  imports = [ ];
}
