{ lib, ... }:

let
  inherit (lib) mkMerge;
in
{
  config = mkMerge [
    { soxin.hardware.bluetooth.enable = true; }
  ];
}
