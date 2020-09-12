{ lib, ... }:

with lib;

{
  options.soxin.hardware.bluetooth.enable = mkEnableOption "Enable bluetooth";
}
