{ mode, config, lib, pkgs, ... }:

with lib;

{
  options = {
    soxin.hardware.bluetooth.enable = mkEnableOption "Enable bluetooth";
  };

  config = mkIf config.soxin.hardware.bluetooth.enable (mkMerge [

    (optionalAttrs (mode == "NixOS") {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    })

    (optionalAttrs (mode == "home-manager") {
      services.blueman-applet.enable = pkgs.stdenv.isLinux;
    })

  ]);
}
