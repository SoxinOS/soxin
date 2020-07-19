{ lib, ... }:

{
  imports = [
    (import ./.. { inherit lib; }).home-manager
  ];

  soxin.hardware.bluetooth.enable = true;
}
