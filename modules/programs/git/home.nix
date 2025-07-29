{ config, lib, ... }:

let
  inherit (lib) mkIf mkMerge;

  cfg = config.soxin.programs.git;
in
{
  config = mkIf cfg.enable {
    programs.git = {
      inherit (cfg)
        enable
        package
        userName
        userEmail
        ;

      lfs = {
        inherit (cfg.lfs) enable;
      };

      signing = mkMerge [
        (mkIf (cfg.signing.key != null) { inherit (cfg.signing) key; })

        (mkIf (cfg.signing.format != null) { inherit (cfg.signing) format; })

        (mkIf (cfg.signing.signByDefault != null) { inherit (cfg.signing) signByDefault; })

        (mkIf (cfg.signing.signer != null) { inherit (cfg.signing) signer; })
      ];
    };
  };
}
