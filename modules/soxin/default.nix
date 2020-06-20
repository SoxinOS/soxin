{ config, lib, ... }:

with lib;

let cfg = config.soxin;
in {
  options = {
    soxin = {
      backend = mkOption {
        type = with types;
          nullOr (enum [ "NixOS" "home-manager" "nix-darwin" ]);
        description = ''
          soxin backend, i.e. whether soxin is imported by a NixOS,
          home-manager or nix-darwin configuration. This is required for soxin
          to operate properly.
        '';
      };

      isNixOS = mkOption {
        type = types.bool;
        default = cfg.backend == "NixOS";
        internal = true;
        readOnly = true;
      };

      isHome = mkOption {
        type = types.bool;
        default = cfg.backend == "home-manager";
        internal = true;
        readOnly = true;
      };

      isDarwin = mkOption {
        type = types.bool;
        default = cfg.backend == "nix-darwin";
        internal = true;
        readOnly = true;
      };
    };
  };

  config = {
    assertions = [{
      assertion = cfg.backend != null;
      message = "soxin.backend is required for soxin to operate properly.";
    }];
  };
}
