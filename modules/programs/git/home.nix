{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge mkOptionDefault;

  cfg = config.soxin.programs.git;
in
{
  config = mkMerge [
    (mkIf (cfg.signing != { }) {
      soxin.programs.git = {
        signing = {
          format =
            if (lib.versionOlder config.home.stateVersion "25.05") then
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
    })

    (mkIf cfg.enable {
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
    })
  ];
}
