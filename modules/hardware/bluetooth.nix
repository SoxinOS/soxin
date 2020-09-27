{ mode, config, lib, ... }:

with lib;

{
  options = {
    soxin.hardware.bluetooth.enable = mkEnableOption "Enable bluetooth";
  };

  config = mkIf config.soxin.hardware.bluetooth.enable (
    if (mode == "NixOS") then {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    } else if (mode == "home-manager") then {
      services.blueman-applet.enable = true;
    } else {});
}
