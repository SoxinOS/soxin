{ mode, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.soxin.programs.git;
in
{
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

      gpgSigningKey = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "git PGP signing key";
      };

      lfs.enable = mkEnableOption "Enable git.lfs";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS") {
      # TODO: NixOS does not currently mirror home-manager
      environment.systemPackages = [ cfg.package ];
    })

    (optionalAttrs (mode == "home-manager") {
      programs.git = {
        inherit (cfg) package userName userEmail;

        enable = true;

        signing = mkIf (cfg.gpgSigningKey != null) {
          key = cfg.gpgSigningKey;
          signByDefault = mkDefault true;
        };

        lfs = { inherit (cfg.lfs) enable; };
      };
    })
  ]);
}

