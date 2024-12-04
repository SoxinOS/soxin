{
  mode,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.soxin.programs.keybase;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    optionalAttrs
    recursiveUpdate
    ;

  inherit (pkgs.hostPlatform) isLinux;
in
{
  options = {
    soxin.programs.keybase = {
      enable = mkEnableOption "Keybase";
      enableFs = recursiveUpdate (mkEnableOption "Keybase filesystem") { default = isLinux; };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS" || mode == "home-manager") {
      services.keybase.enable = true;
      services.kbfs.enable = cfg.enableFs;
    })
  ]);
}
