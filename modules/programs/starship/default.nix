{
  mode,
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.soxin.programs.starship;
in
{
  options = {
    soxin.programs.starship = {
      enable = mkEnableOption "starship prompt";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS") {
      programs.zsh.shellInit = mkAfter ''
        if [ -z "$INSIDE_EMACS" ]; then
          eval "$(${pkgs.starship}/bin/starship init zsh)"
        fi
      '';
    })

    (optionalAttrs (mode == "home-manager") {
      programs.starship = {
        enable = true;
        enableZshIntegration = config.soxin.programs.zsh.enable;
      };
    })
  ]);
}
