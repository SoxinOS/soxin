{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOptionDefault
    ;

  cfg = config.soxin.programs.git;

in
{
  config = mkMerge [
    (mkIf (cfg.signing != { }) {
      soxin.programs.git = {
        signing = {
          format =
            if (lib.versionOlder config.system.stateVersion "25.05") then
              (mkOptionDefault "openpgp")
            else
              (mkOptionDefault null);
          signer =
            let
              defaultSigners = {
                openpgp = lib.getExe config.programs.gpg.package;
                ssh = lib.getExe' pkgs.openssh "ssh-keygen";
                x509 = lib.getExe' config.programs.gpg.package "gpgsm";
              };
            in
            mkIf (cfg.signing.format != null) (mkOptionDefault defaultSigners.${cfg.signing.format});
        };
      };

      programs.git.config = mkMerge [
        (mkIf (cfg.signing.key != null) { user.signingKey = mkDefault cfg.signing.key; })
        (mkIf (cfg.signing.signByDefault != null) {
          commit.gpgSign = mkDefault cfg.signing.signByDefault;
          tag.gpgSign = mkDefault cfg.signing.signByDefault;
        })
        (mkIf (cfg.signing.format != null) {
          gpg = {
            format = mkDefault cfg.signing.format;
            ${cfg.signing.format}.program = mkDefault cfg.signing.signer;
          };
        })
      ];
    })

    (mkIf cfg.enable {
      programs.git = {
        inherit (cfg) enable package;

        lfs = {
          inherit (cfg.lfs) enable;
        };

        config = mkMerge [
          (mkIf (cfg.userName != null) { user.name = cfg.userName; })

          (mkIf (cfg.userEmail != null) { user.email = cfg.userEmail; })
        ];
      };
    })
  ];
}
