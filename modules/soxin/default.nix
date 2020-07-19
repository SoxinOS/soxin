{ config, lib, ... }:

with lib;

let cfg = config.soxin;
in {
  options = {
    home-manager.config = mkOption {
      type = types.attrs;
      default = {};
    };

    nixos.config = mkOption {
      type = types.attrs;
      default = {};
    };
  };
}
