{ config, lib, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    ;

  cfg = config.soxin.programs.git;

in
{
  config = mkIf cfg.enable {
    programs.git = mkMerge [
      {
        inherit (cfg) enable package;

        lfs = { inherit (cfg.lfs) enable; };
      }

      (mkIf (cfg.signing != null) {
        config.commit.gpgSign = mkDefault cfg.signing.signByDefault;
        config.tag.gpgSign = mkDefault cfg.signing.signByDefault;
        config.gpg.program = cfg.signing.gpgPath;
      })

      (mkIf (cfg.signing != null && cfg.signing.key != null) {
        config.user.signingKey = cfg.signing.key;
      })

      (mkIf (cfg.userName != null) {
        config.user.name = cfg.userName;
      })

      (mkIf (cfg.userEmail != null) {
        config.user.email = cfg.userEmail;
      })
    ];
  };
}
