{
  mode,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkOption
    optionals
    types
    ;
in
{
  imports =
    [ ]
    ++ optionals (mode == "NixOS") [ ./nixos.nix ]
    ++ optionals (mode == "home-manager") [ ./home.nix ];

  options = {
    soxin.programs.git = {
      enable = mkEnableOption "git";

      package = mkOption {
        type = types.package;
        default = pkgs.gitAndTools.gitFull;
        defaultText = "pkgs.gitAndTools.gitFull";
        description = "Git package to use.";
      };

      userName = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "git user name";
      };

      userEmail = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "git user email";
      };

      signing = {
        key = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The default signing key fingerprint.

            Set to `null` to let the signer decide what signing key
            to use depending on commit’s author.
          '';
        };

        format = mkOption {
          type = types.nullOr (
            types.enum [
              "openpgp"
              "ssh"
              "x509"
            ]
          );
          defaultText = literalExpression ''
            "openpgp" for state version < 25.05,
            undefined for state version ≥ 25.05
          '';
          description = ''
            The signing method to use when signing commits and tags.
            Valid values are `openpgp` (OpenPGP/GnuPG), `ssh` (SSH), and `x509` (X.509 certificates).
          '';
        };

        signByDefault = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether commits and tags should be signed by default.";
        };

        signer = mkOption {
          type = types.nullOr types.str;
          description = "Path to signer binary to use.";
        };
      };

      lfs.enable = mkEnableOption "Enable git.lfs";
    };
  };
}
