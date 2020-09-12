{ config, lib, ... }:

with lib;

{
  config = mkIf config.soxin.hardware.bluetooth.enable {
    services.blueman-applet.enable = true;
  };
}
