{ mode, config, pkgs, lib, ... }:

let
  cfg = config.soxin.programs.starship;

  inherit (lib)
    mkEnableOption
    mkAfter
    mkIf
    mkMerge
    optionalAttrs
    ;

  inherit (pkgs.hostPlatform)
    isDarwin
    ;
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
      programs.starship = mkMerge [
        {
          enable = true;
          enableZshIntegration = config.soxin.programs.zsh.enable;
        }

        (mkIf (isDarwin /* TODO: && M1 only */) {
          package = pkgs.writeShellScriptBin "starship" ''
            set -euo pipefail

            readonly real_path=/opt/homebrew/bin/starship

            if [[ ! -x $real_path ]]; then
              >&2 echo "Installing starship, please wait."
              brew install starship
            fi

            exec $real_path "$@"
          '';
        })
      ];
    })
  ]);
}
