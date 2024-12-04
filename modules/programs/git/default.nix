{
  mode,
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    optionals
    types
    ;

  signModule = types.submodule {
    options = {
      key = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The default GPG signing key fingerprint.

          Set to `null` to let GnuPG decide what signing key
          to use depending on commit’s author.
        '';
      };

      signByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Whether commits and tags should be signed by default.";
      };

      gpgPath = mkOption {
        type = types.str;
        default = "${pkgs.gnupg}/bin/gpg2";
        defaultText = "\${pkgs.gnupg}/bin/gpg2";
        description = "Path to GnuPG binary to use.";
      };
    };
  };
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

      signing = mkOption {
        type = types.nullOr signModule;
        default = null;
        description = "Options related to signing commits using GnuPG.";
      };

      lfs.enable = mkEnableOption "Enable git.lfs";
    };
  };
}
