{ config, lib, ... }:

with lib;

let
  cfg = config.soxin.hardware.bluetooth
in {
  options.soxin.hardware.bluetooth = {
    enable = mkEnableOption "enable bluetooth";
  };

  config = mkIf cfg.enable {
    nixos.config = {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };

    home-manager.config = {
      services.blueman-applet.enable = true;
    };
  };
}
