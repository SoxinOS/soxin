{ mode, config, lib, ... }:

with lib;

{
  options = {
    soxin.hardware.bluetooth.enable = mkEnableOption "Enable bluetooth";
  };

  config = mkIf config.soxin.hardware.bluetooth.enable (mkMerge [

    (mkIf (mode == "NixOS") {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    })

    (mkIf (mode == "home-manager") {
      services.blueman-applet.enable = true;
    })

  ]);
}
