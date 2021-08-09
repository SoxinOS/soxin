{ mode, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.soxin.programs.keybase;
in
{
  options = {
    soxin.programs.keybase = {
      enable = mkEnableOption "Keybase";
      enableFs =
        recursiveUpdate
          (mkEnableOption "Keybase filesystem")
          { default = true; };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS" || mode == "home-manager") {
      services.keybase.enable = true;
      services.kbfs.enable = cfg.enableFs;
    })
  ]);
}
