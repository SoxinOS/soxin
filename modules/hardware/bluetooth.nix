{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.soxin.workstation.bluetooth;
in {
  options = {
    soxin.workstation.bluetooth = {
      enable = mkEnableOption "Enable bluetooth";
    };
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
