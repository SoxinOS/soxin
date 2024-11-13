{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    ;

  cfg = config.soxin.programs.git;
in
{
  config = mkIf cfg.enable {
    programs.git = {
      inherit (cfg) enable package;

      config = [
        (mkIf (cfg.signing != null) {
          user.signingKey = mkIf (cfg.signing.key != null) cfg.signing.key;
          commit.gpgSign = mkDefault cfg.signing.signByDefault;
          tag.gpgSign = mkDefault cfg.signing.signByDefault;
          gpg.program = cfg.signing.gpgPath;
        })

        (mkIf (cfg.userName != null) {
          user = {
            name = cfg.userName;
          };
        })

        (mkIf (cfg.userEmail != null) {
          user = {
            email = cfg.userEmail;
          };
        })
      ];

      lfs = { inherit (cfg.lfs) enable; };

      signing = cfg.signing;
    };
  };
}
