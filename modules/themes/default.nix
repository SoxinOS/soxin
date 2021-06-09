{ soxin, config, lib, ... }:

with lib;
let
  utils = config.soxin.utils.themes;
in
{
  options = {
    soxin.themes = mkOption {
      type = with types; attrsOf soxin.lib.modules.themes.themeModule;
      default = { };
    };
  };

  imports = [
    ./gruvbox-dark.nix
    ./gruvbox-light.nix
  ];
}
