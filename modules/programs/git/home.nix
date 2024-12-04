{ config, lib, ... }:

let
  inherit (lib) mkIf;

  cfg = config.soxin.programs.git;
in
{
  config = mkIf cfg.enable {
    programs.git = {
      inherit (cfg)
        enable
        package
        signing
        userName
        userEmail
        ;

      lfs = {
        inherit (cfg.lfs) enable;
      };
    };
  };
}
