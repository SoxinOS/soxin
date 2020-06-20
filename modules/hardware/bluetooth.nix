{ config, lib, pkgs, ... }:

with lib;

let
  backend = config.soxin;
  cfg = config.soxin.workstation.bluetooth;
in {
  options = {
    soxin.workstation.bluetooth = {
      enable = mkEnableOption "Enable bluetooth";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf backend.isNixOS {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    })

    (mkIf backend.isHome { services.blueman-applet.enable = true; })
  ]);
}
