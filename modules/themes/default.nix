{ config, lib, ... }:

with lib;
let
  utils = config.soxin.utils.themes;
in
{
  options = {
    soxin.themes = mkOption {
      type = with types; attrsOf utils.themeModule;
      default = { };
    };
  };

  imports = [
    ./gruvbox-dark.nix
  ];

  config = {
    soxin.utils.themes = {
      themeModule = types.submodule {
        options = {
          rofi = mkOption {
            type = utils.rofiModule;
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
    };
  };
}
