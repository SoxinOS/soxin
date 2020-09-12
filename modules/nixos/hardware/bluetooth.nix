{ config, lib, ... }:

with lib;

{
  config = mkIf config.soxin.hardware.bluetooth.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
