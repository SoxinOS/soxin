{ config, lib, ... }:

with lib;

let
  cfg = config.soxin.hardware.bluetooth;
in {
  options.soxin.hardware.bluetooth = {
    enable = mkEnableOption "enable bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # home-manager = {
    #   services.blueman-applet.enable = true;
    # };
    home-manager.useUserPackages.enable = true;
  };
}
